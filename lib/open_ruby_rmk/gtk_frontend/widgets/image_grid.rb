# -*- coding: utf-8 -*-
# This is a nested widget that can be used to draw grids of images and
# let the user interact with them. The images are internally stored as
# a two-dimensional array of CellInfo objects, each subarray representing
# a single row in the grid and each CellInfo a single cell. A CellInfo
# mainly consists of the Gdk::Pixbuf instance used to draw the cell,
# but can contain arbitrary information via its +data+ attribute.
#
# This widget consists basicly of two widgets: A Gtk::Layout, which
# is the canvas we draw the images onto and which may have an arbitrary
# size, and a Gtk::ScrolledWindow that acts as a scrollable container
# for the (possibly very large) canvas, so the user can scroll in order
# to see parts of the canvas otherwise flipping off the window or even
# the screen.
#
# When the widget is to be drawn, the internal array of CellInfo instances
# is iterated, and each’s Pixbuf is then drawn onto the canvas according
# to its position in that array, representing a single cell. Note that
# the internal calculation of the size of the canvas depends on two
# things:
#
# 1. All Pixbufs you add to this widget must share the same dimensions.
#    This does not mean they have to be squared, but each pixbuf’s width
#    must be the same, and likewise each pixbuf’s height must also be the
#    same.
# 2. The internal cells array must always represent a rectangle when
#    the widget is to be drawn, i.e. each row must have the same number
#    of cells. Use +nil+ instead of a CellInfo if you want to leave a
#    single cell blank.
#
# If you don’t obey these rules, you may experience weird effects when
# the widget is drawn.
#
# == Redrawing
# Whenever you change the underlying cells array, that what is visible
# on the screen differs from the internal data. Therefore, whenever you
# change pixbuf information of this widget, call the #redraw! method
# afterwards so the visible part can be resynchronised with the internal
# data. This isn’t done automatically for you, because redrawing the
# widget each time you set something via #[]= in a loop is a severe
# performance hit. So instead, just do the entire loop and _then_ redraw
# the widget by ordering it to do so.
#
# FIXME: Use #redraw_area in methods like #[]= to only update part of
# the canvas, which should have a much better performance than an
# entire #redraw.
#
# == Signals
# This widget provides three highlevel events for dealing with mouse
# interaction on the grid’s cells. They are, in the order in which
# they’re emitted:
#
# [cell_button_press]
#   The user pressed any mouse button over any of the grid’s cells. The
#   signal handlers gets passed a hash with the following keys:
#   [pos]
#     An instance of CellPos, describing the cell that has been
#     clicked.
#   [event]
#     The underlying +button_press+ event. You can use this to find the
#     button that has been pressed.
# [cell_button_motion]
#   The user continues pressing a mouse button and moves the cursor to
#   other cells ("dragging"). Note that in contrast to the normal
#   +button_motion+ signal, this signal only gets triggered on a per-cell
#   basis, so if the cursor never leaves the cell dragging started on
#   before releasing the button, you never receive this signal. The
#   handler gets passed a hash with the following keys:
#   [pos]
#     An instance of CellPos describing the cell the user has hovered
#     to. Depending on the cursor’s velocity and the input device (think
#     touchscreens) this does not necessarily need to be adjascent to
#     the cell you received in the +cell_button_press+ event.
#   [event]
#     The underlying +button_motion+ event.
# [cell_button_release]
#   The user finally releases the pressed mouse button. The signal
#   handler gets passed a hash with the following keys:
#   [pos]
#     An instance of CellPos, describing the cell that has been
#     clicked. +nil+ if the release was outside the canvas
#     (see below).
#   [event]
#     The underlying +button_release+ event.
#
# Note that all these signals are only generated on interaction with the
# actual grid, i.e. if the user clicks, drags, etc. outside the area
# covered by the actual canvas, none of these signals will be emitted
# (an exception to this is the +cell_button_release+ signal which will
# be emitted even if the mouse button is released with the cursor being
# somewhere outwards the canvas, but only if a corresponding +cell_button_pressed+
# signal was encountered before). Also, the initial cell_button_press’
# position and the first cell_button_motion’s +pos+ arguments will not
# be the same, i.e. +cell_button_motion+ will not receive the starting
# point.
#
# == The mask
# Most likely you want your user to interact with the widget by clicking
# on it, dragging, etc. As already mentioned, these interaction causes
# the above signals to be emitted, to which you can connect to act upon
# the user’s request. However, the ImageGrid widget comes with another
# powerful element: The selection mask, or just mask for short. This is
# just an array of CellPos instances that describes all cells in the grid
# that are "masked", usually representing a selection the user made by
# clicking-and-dragging on the widget. By default, no mask is applied
# as the default event handlers do nothing for you, but you can easily
# hook into them and pass the CellInfo instances you will get as arguments
# into the masking methods of this class, e.g. #add_to_mask. Whenever you
# do so, the current mask will be shown to the user by drawing it over
# the actual cell pixbuf images, and you may call #selection to use
# the mask on the grid and retrieve all CellInfo instances it masks.
# The mask is independent from the actual grid, as it’s a purely hypothetical
# construct; you can easily extend the mask to areas that don’t even
# reside inside the grid canvas. Until you call #selection, remember that
# the mask may have dimensions unrelated to the grid canvas.
class OpenRubyRMK::GTKFrontend::Widgets::ImageGrid < Gtk::ScrolledWindow
  type_register
  signal_new :cell_button_press,   GLib::Signal::RUN_LAST, nil, nil, Hash
  signal_new :cell_button_motion,  GLib::Signal::RUN_LAST, nil, nil, Hash
  signal_new :cell_button_release, GLib::Signal::RUN_LAST, nil, nil, Hash

  # A CellPos struct represents the position of a single cell in the
  # grid. You usually don’t construct these objects yourself, but
  # obtain them via the arguments of the cell_button_* signals.
  # These are purely mathematical objects that don’t have any relation
  # to a cell that may or may not be described through the coordinates
  # an instance of this class contains.
  CellPos = Struct.new(:cell_x, :cell_y, :x, :y)

  # A CellInfo object encapsulates the information found in a single
  # cell. This is, most prominently, the Pixbuf instance used to
  # draw the cell, but you can attach any information you like to
  # it by setting +data+ to something useful.
  CellInfo = Struct.new(:pixbuf, :data)

  # The default size the unterlying canvas is set to when
  # the list of CellInfo objects for this widget is empty
  # (mostly applicable immediately after instanciation).
  DEFAULT_SIZE = [32, 32]

  # Set to +true+ if you want to draw visual lines between the cells.
  attr_writer :draw_grid

  # Color for the grid lines if +draw_grid+ is +true+. A four-element
  # array of color values as Cairo expects it, i.e. each component
  # may reach from 0 (nothing) up to 1 (full):
  #   [red, green, blue, alpha]
  attr_accessor :grid_color

  # Creates a new and empty image grid.
  def initialize
    super
    @cells = []
    @layout = Gtk::Layout.new

    @draw_grid = false
    @grid_color = [0.5, 0, 1, 1]
    @mask = []
    @button_is_down = false # Set to true while a mouse button is down

    @layout.set_size(*DEFAULT_SIZE)
    @layout.signal_connect(:expose_event, &method(:on_expose))
    add(@layout)

    @layout.add_events(Gdk::Event::BUTTON_PRESS_MASK | Gdk::Event::BUTTON_RELEASE_MASK | Gdk::Event::POINTER_MOTION_MASK)
    @layout.signal_connect(:button_press_event, &method(:on_button_press))
    @layout.signal_connect(:button_release_event, &method(:on_button_release))
    @layout.signal_connect(:motion_notify_event, &method(:on_motion))

    redraw!
  end

  # Set the CellInfo instance at a specified coordinate. Use +nil+
  # for +cell_info+ if you want an empty cell.
  def []=(x, y, cell_info)
    raise(TypeError, "Not a Gdk::Pixbuf nor nil: #{cell_info.pixbuf.inspect}") if cell_info and !cell_info.pixbuf.kind_of?(Gdk::Pixbuf)

    0.upto(y){|i| @cells[i] = [] unless @cells[i]} unless @cells[y]
    @cells[y][x] = cell_info
  end

  # Retrieves the CellInfo instance (or +nil+) at the specified coordinate.
  def [](x, y)
    @cells[y][x]
  end

  # call-seq:
  #   set_cell(x, y, cell_info)
  #   set_cell(x, y, nil)
  #   set_cell(x, y, pixbuf)
  #   set_cell(x, y, pixbuf, data)
  #
  # Set the CellInfo instance at the specified coordinate. The first form
  # is equal to using #[]= and directly assigns a CellInfo instance to
  # the specified cell coordinate. The second form is equal to using #[]=
  # with +nil+ as the target argument and erases the specified cell by
  # removing its content. The third form is a convenience form for contructing
  # a CellInfo instance around a Gdk::Pixbuf object without adding any
  # additional data, and the fourth form also sets the data on the CellInfo
  # instance. This is particularily useful when using this method with
  # an implicit hash:
  #
  #   grid.set_cell(1, 2, my_pixbuf, :foo => "bar", :baz => "blubb")
  #
  # The Hash instance will be assigned to the generated CellInfo instance’s
  # +data+ attribute and can be retrieved like any other data later on.
  def set_cell(x, y, obj, data = nil)
    if data
      self[x, y] = CellInfo.new(obj, data) # Pixbuf typecheck done in #[]
    else
      case obj
      when Gdk::Pixbuf then self[x, y] = CellInfo.new(obj, data) # Some users may want to store `false'
      when CellInfo    then self[x, y] = obj
      when NilClass    then self[x, y] = nil
      else
        raise(TypeError, "Neither a CellInfo nor a Gdk::Pixbuf: #{obj.inspect}")
      end
    end
  end

  # For symmetry with #set_cell, equal to #[].
  def get_cell(x, y)
    self[x, y]
  end

  # Append an entire row of cells to the bottom of the grid.
  def append_row(cells)
    @cells.push(cells)
  end

  # Same as #append_row, but returns +self+ for method chaining.
  def <<(cells)
    append_row
    self
  end

  # Replace the entire internal array with another. Be *very*
  # careful when using this method and re-read the notes on
  # the internal structure of that array in the class docs.
  def replace(cells)
    @cells.replace(cells)
  end

  # Wipe out the internal array of cells. Does not affect
  # the mask.
  def clear
    @cells.clear
  end

  # True if the grid shall be drawn.
  def draw_grid?
    @draw_grid
  end

  # Recalculate the width and height of the canvas by examining
  # the stored Pixbuf objects (which must all have the same
  # dimensions and in total must sum up to a rectangular area)
  # and then redraw the entire widget. If the internal cells
  # array is empty, resets the underlying canvas to the default
  # dimensions and redraws it.
  def redraw!
    if @cells.empty?
      @layout.set_size(*DEFAULT_SIZE)
      @layout.queue_draw
      return
    end

    # Tell GTK the new size and request a redraw.
    @layout.set_size(*canvas_size)
    redraw
  end

  # Tell GTK to redraw only a certain part of the grid canvas.
  # In contrast to #redraw! this does not re-examine the cells
  # array, i.e. the canvas will not change size when calling this
  # method.
  def redraw_area(x, y, width, height)
    # This is a bit nitty-gritty. `@layout.queue_draw_area' resolves coordinates
    # relative to the scroll window, which is undesired and updates the wrong
    # parts of the canvas. Instead, we directly operate on the canvas and tell
    # GDK to invalidate part of it, which in turn causes GTK to issue the expose
    # event accordingly. In contrast, `@layout.queue_draw' always affects the
    # entire canvas widget, so redrawing that one is possible without having
    # to go down to GDK.
    @layout.bin_window.invalidate(Gdk::Rectangle.new(x, y, width, height), false)
  end

  # Tell GTK to redraw the entire canvas, but don’t recalculate
  # the canvas size. See also #redraw!.
  def redraw
    # <Also see the comments in #redraw_area>
    @layout.queue_draw
  end

  # Calculates the size of the underlying canvas by examining the
  # internal cells array. Return value is a two-element array
  # of form <tt>[width, height]</tt> (both values are pixel values).
  def canvas_size
    # Note this code makes two
    # important assumptions: Each pixbuf has the same dimensions,
    # and the whole tabe is rectangular, i.e. no row has more columns
    # than another, etc.
    [cell_width * @cells.first.count, cell_height * @cells.count]
  end

  # The width of a single cell in pixels.
  def cell_width
    @cells.first.first.pixbuf.width
  end

  # The height of a single cell in pixels.
  def cell_height
    @cells.first.first.pixbuf.height
  end

  # The number of cell rows in the grid, i.e. how many cells are
  # in a single column.
  def row_num
    @cells.count
  end

  # The number of cell columns in the grid, i.e. how many cells are
  # in a single row.
  def col_num
    col = @cells.first
    return 0 unless col
    col.count
  end

  # Adds the given CellPos to the current mask and
  # redraws the affected part of the canvas.
  # Most useful inside the cell_button_* signal handlers.
  def add_to_mask(pos)
    @mask.push(pos)
    redraw_area(pos.x, pos.y, cell_width, cell_height)
  end

  # Replaces the current mask with the rectangle described
  # by the two CellPos instances +corner1+ and +corner2+,
  # taking care of the appropriate redrawing operations.
  # Depending on the coordinates of the two arguments to this
  # method, this method may actually select a stripe or event
  # only a single cell. Entirely clearing the mask is not
  # possible with this method.
  def mask_rectangle(corner1, corner2)
    # Remove anything existing and redraw
    clear_mask

    # Determine which coordinates we need to subtract from which
    first_x_corner, second_x_corner = corner1.cell_x < corner2.cell_x ? [corner1, corner2] : [corner2, corner1]
    first_y_corner, second_y_corner = corner1.cell_y < corner2.cell_y ? [corner1, corner2] : [corner2, corner1]

    # Select the rectangle bounded by upper_left and lower_right
    first_x_corner.cell_x.upto(second_x_corner.cell_x) do |cell_x|
      first_y_corner.cell_y.upto(second_y_corner.cell_y) do |cell_y|
        pos = CellPos.new(cell_x, cell_y, cell_x * cell_width, cell_y * cell_height)
        @mask.push(pos)
      end
    end

    # Redraw the area bounded by upper_left and lower_right
    redraw_area(first_x_corner.x,
                first_y_corner.y,
                (second_x_corner.x + cell_width)  - first_x_corner.x, # Right edge of second cell - Left edge of first cell
                (second_y_corner.y + cell_height) - first_y_corner.y) # Likewise for vertical axis
  end

  # Clears the mask and redraws the canvas without
  # it.
  def clear_mask
    @mask.clear
    redraw
  end

  # Checks if the given CellPos is already part of the
  # mask, and if so, returns +true+, otherwise +false+.
  def masked?(pos)
    @mask.include?(pos)
  end

  # The mask, i.e. an array of all CellPos instances
  # that have been added to the mask.
  def mask
    @mask
  end

  # Inverts the current mask, i.e. unmasks all currently masked
  # cells and masks everything else. Note this method implicitely
  # clips the mask to the current canvas size. Automatically
  # redraws the widget.
  def invert_mask
    new_mask = []
    0.upto(col_num) do |y|
      0.upto(row_num) do |x|
        pos = CellPos.new(x, y, x * cell_width, y * cell_height)

        new_mask << pos unless masked?(pos)
      end
    end

    @mask.replace(new_mask)
    redraw
  end

  # Clears the current mask and then masks everything.
  # Implicitely clips the mask to the current canvas size.
  # Automatically redraws the widget.
  def mask_all
    @mask.clear

    0.upto(col_num) do |y|
      0.upto(row_num) do |x|
        pos = CellPos.new(x, y, x * cell_width, y * cell_height)

        @mask << pos
      end
    end

    redraw
  end

  # Applies the mask for selection on the grid, returning all
  # CellInfo instances that match it. That is, returns
  # all CellInfo objects corresponding to all CellPos objects
  # in the mask.
  # Does not clear the mask.
  def selection
    @mask.map{|pos| get_cell(pos.cell_x, pos.cell_y)}
  end

  private

  ########################################
  # Custom default event handlers

  def signal_do_cell_button_press(*)
  end

  def signal_do_cell_button_motion(*)
  end

  def signal_do_cell_button_release(*)
  end

  ########################################
  # Event handlers

  def on_expose(_, event)
    return if @cells.empty?
    cc = @layout.bin_window.create_cairo_context

    # TODO: Only redraw the parts that need to be redrawn,
    # available via `event.region'. The bounding box of all
    # places that need to be redrawn is available via
    # `event.area', which may be easier to handle on the cost
    # of redrawing parts between them that don’t need to be
    # redrawn.

    # TODO: Layers!
    # TODO: Instead of holding all the images in memory which
    # may consume extreme amounds depending on number of images,
    # fire a redraw_cell event here so the user can allocate the
    # image required for this cell temporarily.
    # TODO: Fire a redraw_layer event for non-grid layers.
    @cells.each_with_index do |row, y|
      row.each_with_index do |info, x|
        next if info.nil? # Empty cell

        cc.set_source_pixbuf(info.pixbuf, x * info.pixbuf.width, y * info.pixbuf.height)
        cc.paint
      end
    end

    # Draw the grid if requested. Note the 0.5px offset when drawing creating
    # the paths; this is required since the coordinates really apply to the
    # edges between the pixels, and a line width of 1 would mean 0.5px to either
    # side of the edge, which is impossible and results in 1 semi-opaque pixel
    # to either side. By offsetting by 0.5 the edge *is* on the pixel’s middle,
    # and expanding by 0.5px to either side exactly snaps into the real pixel
    # edges, causing a sharp, 1px thick line. Without this trick, we would end
    # up with a 2px thick, semi-opaque line (as explained already).
    if @draw_grid
      width, height = canvas_size

      # Create the Cairo paths for the vertical lines
      0.step(width, @cells.first.first.pixbuf.width) do |x|
        cc.move_to(x + 0.5, 0)
        cc.line_to(x + 0.5, height)
      end

      # Create the Cairo paths for the horizontal lines
      0.step(height, @cells.first.first.pixbuf.height) do |y|
        cc.move_to(0, y + 0.5)
        cc.line_to(width, y + 0.5)
      end

      # Stroke the paths specified earlier with the requested colour.
      cc.set_source_rgba(*@grid_color)
      cc.line_width = 1
      cc.stroke
    end

    # If a mask is active, also draw that one.
    @mask.each do |pos|
      cc.rectangle(pos.x, pos.y, cell_width, cell_height)
    end
    cc.set_source_rgba(1, 0, 0, 0.5)
    cc.fill

    true # Event completely handled
  end

  def on_button_press(_, event)
    # Snap click coordinates to cell grid
    pos   = CellPos.new(event.coords[0].to_i / cell_width, event.coords[1].to_i / cell_height)
    pos.x = pos.cell_x * cell_width
    pos.y = pos.cell_y * cell_height

    # Only care about clicks on the grid, not about those next to it
    return if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    @button_is_down = true
    signal_emit :cell_button_press, :pos => pos, :event => event
  end

  def on_motion(_, event)
    return unless @button_is_down

    # Snap click coordinates to cell grid
    pos   = CellPos.new(event.coords[0].to_i / cell_width, event.coords[1].to_i / cell_height)
    pos.x = pos.cell_x * cell_width
    pos.y = pos.cell_y * cell_height

    # Only care about clicks on the grid, not about those next to it
    return if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    signal_emit :cell_button_motion, :pos => pos, :event => event
  end

  def on_button_release(_, event)
    return unless @button_is_down
    @button_is_down = false

    pos   = CellPos.new(event.coords[0].to_i / cell_width, event.coords[1].to_i / cell_height)
    pos.x = pos.cell_x * cell_width
    pos.y = pos.cell_y * cell_height

    # Don’t provide coordinates outside the cell grid
    pos = nil if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    signal_emit :cell_button_release, :event => event, :pos => pos
  end

end
