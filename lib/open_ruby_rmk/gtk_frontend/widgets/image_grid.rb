# -*- coding: utf-8 -*-
# This is a nested widget that can be used to draw grids of images and
# let the user interact with them. The images are internally stored as
# a three-dimensional array of CellInfo objects, each subarray representing
# a single layer in the grid and each CellInfo a single column (which itself
# is an array representing the actual cells). A CellInfo
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
# 2. The internal cells array if each layer must always represent a rectangle
#    when the widget is to be drawn, i.e. each row must have the same number
#    of cells. Use +nil+ instead of a CellInfo if you want to leave a
#    single cell blank. Note the grid doesn’t have to be a cube, so you may
#    choose any number of Z layers.
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
# This widget provides three highlevel signals for dealing with mouse
# interaction on the grid’s cells and a few other things.
#
# === The mouse signals
# Listed in the order in which they are emitted:
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
# All positions provided by the signals are always relative to the
# _active_ Z layer, which defaults to 0 and can be configured via
# the #active_layer attribute. Apart from this, the active layer
# does not have any impact on any of the methods of this class.
#
# === The other signals
# Listed in no particular ordering.
#
# [draw_background]
#   Emitted when part or whole of the widget’s background needs
#   to be redrawn. By default, does nothing (but note that
#   GTK by default clears any widget’s Cairo context to the
#   default widget color before you can do anything). It
#   takes a whole bunch of arguments:
#   [event]
#     The underlying +expose+ event.
#   [cairo_context]
#     The Cairo::Context you want to draw your background upon.
#   [rectangle]
#     A Gdk::Rectangle instance describing the area that needs
#     to have the background redrawn.
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
# hook into them and pass the CellPos instances you will get as arguments
# into the masking methods of this class, e.g. #add_to_mask. Whenever you
# do so, the current mask will be shown to the user by drawing it over
# the actual cell pixbuf images, and you may call #selection or #apply to use
# the mask on the grid and retrieve all CellInfo instances it masks.
# The mask is independent from the actual grid, as it’s a purely hypothetical
# construct; you can easily extend the mask to areas that don’t even
# reside inside the grid canvas. Until you apply it, remember that
# the mask may have dimensions unrelated to the grid canvas. Also note
# that while it’s hypothetically possible to have the mask span multiple
# Z layers, in general you want to avoid this to prevent really confusing
# effects.
class OpenRubyRMK::GTKFrontend::Widgets::ImageGrid < Gtk::ScrolledWindow
  include Enumerable

  type_register
  signal_new :cell_button_press,   GLib::Signal::RUN_LAST, nil, nil, Hash
  signal_new :cell_button_motion,  GLib::Signal::RUN_LAST, nil, nil, Hash
  signal_new :cell_button_release, GLib::Signal::RUN_LAST, nil, nil, Hash
  signal_new :draw_background,     GLib::Signal::RUN_FIRST, nil, nil, Hash

  # A CellPos struct represents the position of a single cell in the
  # grid. You usually don’t construct these objects yourself, but
  # obtain them via the arguments of the cell_button_* signals.
  # These are purely mathematical objects that don’t have any relation
  # to a cell that may or may not be described through the coordinates
  # an instance of this class contains.
  CellPos = Struct.new(:cell_x, :cell_y, :cell_z, :x, :y)

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

  ##
  # :attr_accessor: active_layer
  #
  # The currently active layer’s index a user is operating on.

  # Creates a new and empty image grid.
  # == Parameters
  # [cell_width]
  #   The initial width of a single cell in pixels.
  # [cell_height]
  #   The initial height of a single cell in pixels.
  def initialize(cell_width, cell_height)
    super()
    @cells          = []
    @active_layer   = 0
    @layout         = Gtk::Layout.new

    @cell_width     = cell_width
    @cell_height    = cell_height
    @draw_grid      = false
    @grid_color     = [0.5, 0, 1, 1]
    @mask           = []
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
  def []=(x, y, z, cell_info)
    raise(TypeError, "Not a Gdk::Pixbuf nor nil: #{cell_info.pixbuf.inspect}") if cell_info and !cell_info.pixbuf.kind_of?(Gdk::Pixbuf)

    0.upto(z) do |iz|
      @cells[iz] = [] unless @cells[iz]
      0.upto(x) do |ix|
        @cells[iz][ix] = [] unless @cells[iz][ix]
      end
    end

    @cells[z][x][y] = cell_info # Fills the X array with nils if necessary
  end

  # Retrieves the CellInfo instance (or +nil+) at the specified coordinate.
  def [](x, y, z)
    @cells[z][x][y]
  end

  # See attribute.
  def active_layer # :nodoc:
    @active_layer
  end

  # See attribute.
  def active_layer=(z) # :nodoc:
    raise(RangeError, "Z index out of bounds: #{z} (must be between 0 and #{layer_num - 1}, both inclusive)") if z < 0 or z >= layer_num
    @active_layer = z
  end

  # The width of a single cell, in pixels.
  def cell_width
    @cell_width
  end

  # The height of a single cell, in pixels.
  def cell_height
    @cell_height
  end

  # Adjust the width of all the cells. Automatically
  # redraws the canvas.
  def cell_width=(val)
    @cell_width = val
    redraw
  end

  # Adjust the height of all the cells. Automatically
  # redraws the canvas.
  def cell_height=(val)
    @cell_height = val
    redraw
  end

  # call-seq:
  #   set_cell(x, y, z, cell_info)
  #   set_cell(x, y, z, nil)
  #   set_cell(x, y, z, pixbuf)
  #   set_cell(x, y, z, pixbuf, data)
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
  def set_cell(x, y, z, obj, data = nil)
    if data
      self[x, y, z] = CellInfo.new(obj, data) # Pixbuf typecheck done in #[]
    else
      case obj
      when Gdk::Pixbuf then self[x, y, z] = CellInfo.new(obj, data) # Some users may want to store `false'
      when CellInfo    then self[x, y, z] = obj
      when NilClass    then self[x, y, z] = nil
      else
        raise(TypeError, "Neither a CellInfo nor a Gdk::Pixbuf: #{obj.inspect}")
      end
    end
  end

  # For symmetry with #set_cell, equal to #[].
  def get_cell(x, y, z)
    self[x, y, z]
  end

  # Iterates over all cells in this grid and yields their
  # coressponding CellInfo and CellPos objects to the block.
  # +cell+ may be +nil+ for an empty cell.
  def each
    @cells.each_with_index do |layer, z|
      layer.each_with_index do |col, x|
        col.each_with_index do |cell, y|
          pos = CellPos.new(x, y, z, x * @cell_width, y * @cell_height)
          yield(cell, pos)
        end
      end
    end
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
    # and the whole table is rectangular, i.e. no row has more columns
    # than another, etc.
    [@cell_width * @cells.first.count, @cell_height * @cells.first.first.count]
  end

  # The number of cell rows in the grid, i.e. how many cells are
  # in a single column.
  def row_num
    return 0 unless @cells.first
    return 0 unless @cells.first.first
    @cells.first.first.count
  end

  # The number of cell columns in the grid, i.e. how many cells are
  # in a single row.
  def col_num
    layer = @cells.first
    return 0 unless layer
    layer.count
  end

  # The number of grid layers in the grid, i.e. how many
  # levels the grid is deep.
  def layer_num
    @cells.count
  end

  # Inserts an empty layer at Z index +z+. All higher
  # layers are shifted up by one. A +z+ of -1 appends
  # the layer onto the top of the layer stack.
  def insert_layer(z)
    @cells.insert(z, Array.new(col_num){Array.new(row_num)})
  end

  # Adds the given CellPos to the current mask and
  # redraws the affected part of the canvas.
  # Most useful inside the cell_button_* signal handlers.
  def add_to_mask(pos)
    @mask.push(pos)
    redraw_area(pos.x, pos.y, @cell_width, @cell_height)
  end

  # Replaces the current mask with the rectangle described
  # by the two CellPos instances +corner1+ and +corner2+,
  # taking care of the appropriate redrawing operations.
  # Depending on the coordinates of the two arguments to this
  # method, this method may actually select a stripe or even
  # only a single cell. Entirely clearing the mask is not
  # possible with this method.
  # The two corner’s Z layer indices must be equal, otherwise
  # a RuntimeError is raised.
  def mask_rectangle(corner1, corner2)
    raise("Z layer mismatch: #{corner1.cell_z} vs. #{corner2.cell_z}") unless corner1.cell_z == corner2.cell_z

    # Remove anything existing and redraw
    clear_mask

    # Determine which coordinates we need to subtract from which
    first_x_corner, second_x_corner = corner1.cell_x < corner2.cell_x ? [corner1, corner2] : [corner2, corner1]
    first_y_corner, second_y_corner = corner1.cell_y < corner2.cell_y ? [corner1, corner2] : [corner2, corner1]

    # Select the rectangle bounded by upper_left and lower_right
    first_x_corner.cell_x.upto(second_x_corner.cell_x) do |cell_x|
      first_y_corner.cell_y.upto(second_y_corner.cell_y) do |cell_y|
        pos = CellPos.new(cell_x, cell_y, corner1.cell_z, cell_x * @cell_width, cell_y * @cell_height)
        @mask.push(pos)
      end
    end

    # Redraw the area bounded by upper_left and lower_right
    redraw_area(first_x_corner.x,
                first_y_corner.y,
                (second_x_corner.x + @cell_width)  - first_x_corner.x, # Right edge of second cell - Left edge of first cell
                (second_y_corner.y + @cell_height) - first_y_corner.y) # Likewise for vertical axis
  end

  # Replaces the mask by a mask that covers all cells that have
  # the same associated information as the cell at +pos+, and
  # are adjascent to that cell (recursively). This is like the
  # "magic selection" known from painting programs.
  #
  # Note that this method depends on your data to implement a
  # meaningful == method. Implicitely clips the mask to the
  # grid.
  def mask_adjascent(source_pos)
    #adjascent = [source_pos]
    #source    = get_cell(source_pos.cell_x, source_pos.cell_y)
    #
    #loop do
    #  found = []
    #
    #  each do |cell_info, pos|
    #    xrange = Range.new(pos.cell_x - 1, pos.cell_x + 1)
    #    yrange = Range.new(pos.cell_y - 1, pos.cell_y + 1)
    #
    #    # A tile is adjascent, if it is *either* horizontally *or*
    #    # vertically next to the source tile, but *not* if both
    #    # (because then it’s diagonally placed).
    #    result = adjascent.any? do |apos|
    #      p [apos, pos, xrange, xrange.include?(apos.cell_x)]
    #    end
    #
    #    #if adjascent.any?{|apos| (xrange.include?(apos.cell_x) || yrange.include?(apos.cell_y)) && !(xrange.include?(apos.cell_x) && yrange.include?(apos.cell_y))}
    #      # Now that we know that is’s an adjascent tile, check if it
    #      # uses the same cell information.
    #    #  found << pos if source.data == cell_info.data
    #    #end
    #  end
    #
    #  break if found.empty?
    #  adjascent.concat(found)
    #end
    #
    #@mask.replace(adjascent)
    #redraw
    raise(NotImplementedError, "Someone needs to implement magic selection.")
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
  #
  # Raises a RuntimeError if not all masked fields have the same
  # Z layer index.
  def invert_mask
    first_z = @mask.first.cell_z
    if err = @mask.find{|pos| pos.cell_z != first_z} # Single = intended
      raise("Z layer mismatch: #{first_z} at (0|0) vs. #{err.cell_z} at (#{err.cell_x}|#{err.cell_y})")
    end

    new_mask = []
    0.upto(col_num) do |y|
      0.upto(row_num) do |x|
        pos = CellPos.new(x, y, first_z, x * @cell_width, y * @cell_height)

        new_mask << pos unless masked?(pos)
      end
    end

    @mask.replace(new_mask)
    redraw
  end

  # Clears the current mask and then masks everything
  # on the given layer.
  # Implicitely clips the mask to the current canvas size.
  # Automatically redraws the widget.
  def mask_layer(z)
    @mask.clear

    0.upto(col_num) do |y|
      0.upto(row_num) do |x|
        pos = CellPos.new(x, y, z, x * @cell_width, y * @cell_height)

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
    @mask.map{|pos| get_cell(pos.cell_x, pos.cell_y, pos.cell_z)}
  end

  # Applies the mask on the grid, yielding all matching
  # CellPos and their corresponding CellInfo instances
  # to the block one at a time (don’t assume a specific
  # order). The return value of the block when called for
  # a specific cell is used to replace that cells data,
  # and may be in one of these forms:
  #
  # [+CellInfo+ instance]
  #   This will simply be used as-is to replace the current
  #   value of the cell.
  # [<tt>Gdk::Pixbuf</tt> instance]
  #   Replaces the cell’s value with a CellInfo whose +pixbuf+
  #   attribute is set to this (by-reference). The CellInfo’s
  #   +data+ will be +nil+.
  # [Two-element array]
  #   Replaces the cell’s value with a CellInfo whose +pixbuf+
  #   attribute is set to the array’s first element and its
  #   +data+ attribute set to the array’s second element.
  # [nil]
  #   This cell’s value is emptied, i.e. no CellInfo instance
  #   will be associated with the cell afterwards.
  #
  # Does not clear the mask.
  def apply
    @mask.each do |pos|
      result = yield(pos, get_cell(pos.cell_x, pos.cell_y, pos.cell_z))
      case result
      when CellInfo    then set_cell(pos.cell_x, pos.cell_y, pos.cell_z, result)
      when Gdk::Pixbuf then set_cell(pos.cell_x, pos.cell_y, pos.cell_z, CellInfo.new(result))
      when Array       then set_cell(pos.cell_x, pos.cell_y, pos.cell_z, CellInfo.new(result[0], result[1]))
      when NilClass    then set_cell(pos.cell_x, pos.cell_y, pos.cell_z, nil)
      else
        raise(TypeError, "Don't know how to convert result for (#{pos.cell_x}|#{pos.cell_y}|#{pos.cell_z}) to a CellInfo: #{result.inspect}")
      end
    end
  end

  # Same as #apply, but clears the mask afterwards.
  def apply!(&block)
    apply(&block)
    clear_mask
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

  def signal_do_draw_background(*)
  end

  ########################################
  # Event handlers

  def on_expose(_, event)
    return if @cells.empty?
    cc = @layout.bin_window.create_cairo_context

    # Allow the user to draw the background the way he likes
    signal_emit :draw_background,
                :cairo_context => cc,
                :event => event,
                :rectangle => Gdk::Rectangle.new(0, 0, col_num * @cell_width, row_num * @cell_height)

    # TODO: Only redraw the parts that need to be redrawn,
    # available via `event.region'. The bounding box of all
    # places that need to be redrawn is available via
    # `event.area', which may be easier to handle on the cost
    # of redrawing parts between them that don’t need to be
    # redrawn.

    # TODO: Instead of holding all the images in memory which
    # may consume extreme amounds depending on number of images,
    # fire a redraw_cell event here so the user can allocate the
    # image required for this cell temporarily.
    # TODO: Fire a redraw_layer event for non-grid layers.
    @cells.each_with_index do |layer, z|
      layer.each_with_index do |col, x|
        col.each_with_index do |info, y|
          next if info.nil? # Empty cell

          cc.set_source_pixbuf(info.pixbuf, x * info.pixbuf.width, y * info.pixbuf.height)
          cc.paint
        end
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
      0.step(width, @cells.first.first.first.pixbuf.width) do |x|
        cc.move_to(x + 0.5, 0)
        cc.line_to(x + 0.5, height)
      end

      # Create the Cairo paths for the horizontal lines
      0.step(height, @cells.first.first.first.pixbuf.height) do |y|
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
      cc.rectangle(pos.x, pos.y, @cell_width, @cell_height)
    end
    cc.set_source_rgba(1, 0, 0, 0.5)
    cc.fill

    true # Event completely handled
  end

  def on_button_press(_, event)
    # Snap click coordinates to cell grid
    pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
    pos.x = pos.cell_x * @cell_width
    pos.y = pos.cell_y * @cell_height

    # Only care about clicks on the grid, not about those next to it
    return if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    @button_is_down = true
    signal_emit :cell_button_press, :pos => pos, :event => event
  end

  def on_motion(_, event)
    return unless @button_is_down

    # Snap click coordinates to cell grid
    pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
    pos.x = pos.cell_x * @cell_width
    pos.y = pos.cell_y * @cell_height

    # Only care about clicks on the grid, not about those next to it
    return if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    signal_emit :cell_button_motion, :pos => pos, :event => event
  end

  def on_button_release(_, event)
    return unless @button_is_down
    @button_is_down = false

    pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
    pos.x = pos.cell_x * @cell_width
    pos.y = pos.cell_y * @cell_height

    # Don’t provide coordinates outside the cell grid
    pos = nil if pos.cell_x < 0 or pos.cell_x >= col_num or pos.cell_y < 0 or pos.cell_y >= row_num

    signal_emit :cell_button_release, :event => event, :pos => pos
  end

end
