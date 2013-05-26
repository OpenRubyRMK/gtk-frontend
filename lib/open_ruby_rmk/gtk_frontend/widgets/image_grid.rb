# -*- coding: utf-8 -*-

# This is a nested widget that can be used to draw grids of images and
# let the user interact with them. It consists of a number of layers
# which may either be cell-oriented (mainly) or allow for arbitraryly
# positioned objects. The images are internally stored in the cell layers
# (class CellLayer) in a two-dimensional array representing the given
# layer’s table structure or in the PixelObject objects for PixelLayer
# instances.
#
# In the CellLayer instances, the actual information is stored inside
# CellInfo objects, which mainly consist of the Gdk::Pixbuf instance
# used to draw the cell, but can contain arbitrary information via its
# +data+ attribute.
#
# This widget consists basicly of two widgets: A Gtk::Layout, which
# is the canvas we draw the images onto and which may have an arbitrary
# size, and a Gtk::ScrolledWindow that acts as a scrollable container
# for the (possibly very large) canvas, so the user can scroll in order
# to see parts of the canvas otherwise flipping off the window or even
# the screen.
#
# When the widget is to be drawn, all layers are iterated bottom to
# top, and each’s Pixbuf is then drawn onto the canvas according
# to its position in their respective layer, as interpreted by
# the layer type. Note that the internal calculation of the size
# of the canvas depends on two things:
#
# 1. All Pixbufs you add to CellLayers in this widget must share the same dimensions.
#    This does not mean they have to be squared, but each pixbuf’s width
#    must be the same, and likewise each pixbuf’s height must also be the
#    same. This restriction does not apply to PixelLayer layers.
# 2. The internal cells array of each each CellLayer must always represent a rectangle
#    when the widget is to be drawn, i.e. each row must have the same number
#    of cells (also, each CellLayer should use the same number of
#    cells to prevent weird drawing effects). Use +nil+ instead of a CellInfo
#    if you want to leave a single cell blank. Note the grid doesn’t have to be
#    a cube, so you may choose any number of Z layers (you can freely intermix
#    normal CellLayer instances with PixelLayers).
#
# If you don’t obey these rules, you may experience weird effects when
# the widget is drawn.
#
# == Redrawing
# Whenever you change the underlying layer and cell arrays, that what is visible
# on the screen differs from the internal data. Therefore, whenever you
# change pixbuf information of this widget, call the #redraw! method
# afterwards so the visible part can be resynchronised with the internal
# data. This isn’t done automatically for you, because redrawing the
# widget each time you set something in a loop is a severe
# performance hit. So instead, just do the entire loop and _then_ redraw
# the widget by ordering it to do so.
#
# FIXME: Use #redraw_area in methods like #insert_layer to only update part of
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
#     clicked. Note that for PixelLayers, +cell_x+ and +cell_y+ are
#     blank and +x+ and +y+ are set to the real pixel coodinates of
#     the click rather than simplified cell coordinates.
#   [event]
#     The underlying +button_press+ event. You can use this to find the
#     button that has been pressed.
# [cell_button_motion]
#   The user continues pressing a mouse button and moves the cursor to
#   other cells ("dragging"). Note that in contrast to the normal
#   +button_motion+ signal, this signal only gets triggered on a per-cell
#   basis (this is not the case for PixelLayers), so if the cursor never
#   leaves the cell dragging started on before releasing the button,
#   you never receive this signal. The
#   handler gets passed a hash with the following keys:
#   [pos]
#     An instance of CellPos describing the cell the user has hovered
#     to. Depending on the cursor’s velocity and the input device (think
#     touchscreens) this does not necessarily need to be adjascent to
#     the cell you received in the +cell_button_press+ event. For PixelLayers,
#     +cell_x+ and +cell_y+ are blank and +x+ and +y+ are set to the real
#     event coordinates.
#   [event]
#     The underlying +button_motion+ event.
# [cell_button_release]
#   The user finally releases the pressed mouse button. The signal
#   handler gets passed a hash with the following keys:
#   [pos]
#     An instance of CellPos, describing the cell that has been
#     clicked. +nil+ if the release was outside the canvas
#     (see below). For PixelLayers, +cell_x+ and +cell_y+ are blank
#     and +x+ and +y+ are set to the real event coordinates.
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
# does not have any impact on most of the methods of this class.
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
#
# The mask can only be applied to CellLayers, and inventing CellPos instances
# pointing to PixelLayers may cause unexpected effects.
class OpenRubyRMK::GTKFrontend::Widgets::ImageGrid < Gtk::ScrolledWindow
  include Enumerable

  # Base class for all layers on the grid.
  class Layer

    # The Z layer we sit on.
    attr_reader :z

    # Create a layer which is supposed to sit on the given Z
    # coordinate.
    def initialize(z)
      @z = z
    end

    # (Private API). Set the Z layer this layer resides on.
    # This method has to be called each time the layer is moved
    # around.
    def z=(val) # :nodoc:
      @z = val
    end

    # Called when the grid widget needs to be redrawn.
    # This method receives a Cairo::Context and a Gdk::Rectangle
    # describing the region that needs to be updated in pixels.
    # It must be overridden in a subclass.
    #
    # +opts+ is a hash that may contain the following settings:
    # [:alpha]
    #   Paint (Cairo::Context#paint) everything with the given alpha
    #   value.
    def expose(cc, rect, opts)
      raise(NotImplementedError, "This must be overridden in a subclass.")
    end

  end

  # A layer consisting solely for rastered cells, i.e.
  # a table.
  class CellLayer < Layer
    include Enumerable

    # The width of a single cell, in pixels.
    attr_accessor :cell_width
    # The height of a single cell, in pixels.
    attr_accessor :cell_height

    # Create a new layer with the given dimensions.
    def initialize(z, width, height, cell_width, cell_height)
      super(z)

      @table       = Array.new(width){Array.new(height)}
      @cell_width  = cell_width
      @cell_height = cell_height
    end

    # Human-readable description
    def inspect
      "#<#{self.class} #{col_num}x#{row_num} z=#{z}>"
    end

    # Iterate over each column and their respective cells, yielding
    # the CellInfo objects.
    def each
      return enum_for(__method__) unless block_given?

      @table.each{|col| col.each{|cell| yield(cell)}}
    end

    # Iterate over each column and their respective cells, yielding
    # the CellInfo object and a corresponding CellPos object.
    def each_with_pos
      return enum_for(__method__) unless block_given?

      @table.each_with_index{|col, x| col.each_with_index{|cell, y| yield(cell, CellPos.new(x, y, self.z, x * @cell_width, y * @cell_height))}}
    end

    # Number of columns, i.e. the width, of the table.
    def col_num
      @table.length
    end

    # Number of rows in a column, i.e. the height of the table.
    def row_num
      @table.first.length
    end

    # Resets the number of columns to +val+, creating
    # empty columns at the right end or removing them
    # from there as necessary.
    def col_num=(val)
      # If less than now, cut off. Otherwise, append
      # empty columns.
      if val < col_num
        @table.replace(@table[0..val])
      else
        (val - col_num).times do
          insert_col(-1)
        end
      end
    end

    # Resets the number of rows to +val+, creating
    # empty rows at the bottom end or removing them
    # from there as necessary.
    def row_num=(val)
      return if val == row_num

      # If less than now, cut off. Otherwise, append
      # empty rows.
      if val <= row_num
        @table.each{|col| col.replace(col[0..val])}
      else
        (val - row_num).times do
          insert_row(-1)
        end
      end
    end

    # Set both the #col_num and #row_num at once to
    # the given values (+width+ being the new number of
    # columns and +height+ the new number of rows). The
    # same semantics as for #col_num= and #row_num= apply.
    def resize!(width, height)
      self.col_num = height
      self.row_num = width
    end

    # Insert an empty column at X index +x+.
    # All columns beyond +x+ are moved one to the right.
    # An +x+ of -1 appends a new column at the right end.
    def insert_col(x)
      @table.insert(x, Array.new(row_num))
    end
    alias insert_column insert_col

    # Insert an empty row at Y index +y+ on all
    # layers. All rows below +y+ are moved one
    # to the bottom. A +y+ of -1 appends a new
    # row at the bottom end.
    def insert_row(y)
      @table.each{|col| col.insert(y, nil)}
    end

    # Set the CellInfo instance at a specified coordinate. Use +nil+
    # for +cell_info+ if you want an empty cell. Note that this method
    # automatically creates empty rows and columns if you set a cell
    # outside the current dimensions of the table.
    def set_cell(x, y, cell_info)
      raise(TypeError, "Not a Gdk::Pixbuf nor nil: #{cell_info.pixbuf.inspect}") if !cell_info.nil? and !cell_info.pixbuf.kind_of?(Gdk::Pixbuf)

      0.upto(x) do |ix|
        @table[ix] = [] unless @table[ix]
      end

      @table[x][y] = cell_info # Fills the X array with nils if necessary
    end

    # Retrieves the CellInfo instance (or +nil+) at the specified coordinate.
    def [](x, y)
      raise(RangeError, "X out of range (>= #{@table.length})") if x >= @table.length
      raise(RangeError, "Y out of range (>= #{@table.first.length}") if y >= @table.first.length

      @table[x][y]
    end

    # call-seq:
    #   self[x, y] = cell_info
    #   self[x, y] = nil
    #   self[x, y] = pixbuf
    #   self[x, y] = [pixbuf, data]
    #
    # Set the CellInfo instance at the specified coordinate. The first form
    # is equal to using #set_cell and directly assigns a CellInfo instance to
    # the specified cell coordinate. The second form is equal to using #set_cell
    # with +nil+ as the target argument and erases the specified cell by
    # removing its content. The third form is a convenience form for contructing
    # a CellInfo instance around a Gdk::Pixbuf object without adding any
    # additional data, and the fourth form also sets the data on the CellInfo
    # instance. That form can be used like this:
    #
    #   grid[1, 2] = [my_pixbuf, {:foo => "bar", :baz => "blubb"}]
    #
    # The Hash instance will be assigned to the generated CellInfo instance’s
    # +data+ attribute and can be retrieved like any other data later on.
    def []=(x, y, obj)
      if obj.respond_to?(:to_ary)
        set_cell(x, y, CellInfo.new(obj.to_ary.first, obj.to_ary.last)) # Pixbuf typecheck done in #set_cell
      else
        case obj
        when Gdk::Pixbuf then set_cell(x, y, CellInfo.new(obj))
        when CellInfo then set_cell(x, y, obj)
        when NilClass then set_cell(x, y, nil)
        else
          raise(TypeError, "Neither a CellInfo nor an array nor a Gdk::Pixbuf: #{obj.inspect}")
        end
      end
    end

    def expose(cc, rect, opts)
      # FIXME: For now, just redraw everything and ignore +rect+
      @table.each_with_index do |col, x|
        col.each_with_index do |info, y|
          next if info.nil? # Empty cell

          cc.set_source_pixbuf(info.pixbuf, x * info.pixbuf.width, y * info.pixbuf.height)

          if opts[:alpha]
            cc.paint(opts[:alpha])
          else
            cc.paint
          end
        end
      end
    end

  end

  class PixelLayer < Layer
    include Enumerable

    class PixelObject < Gdk::Rectangle

      attr_accessor :info

      def initialize(x, y, width, height, info = {})
        super(x, y, width, height)
        @info = info
      end

    end

    def initialize(z)
      super(z)

      @objects = []
    end

    def add_object(x, y, width, height, info = {})
      @objects << PixelObject.new(x, y, width, height, info.dup)
    end

    def each
      return enum_for(__method__) unless block_given?

      @objects.each{|obj| yield(obj)}
    end

    def expose(cc, rect, opts)
      # FIXME
    end

  end

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

  # Set to a value between 0 and 1, denoting the alpha value to
  # apply to higher layers. Defaults to 0.5.
  attr_accessor :alpha_layers

  # Color for the grid lines if +draw_grid+ is +true+. A four-element
  # array of color values as Cairo expects it, i.e. each component
  # may reach from 0 (nothing) up to 1 (full):
  #   [red, green, blue, alpha]
  attr_accessor :grid_color

  # Creates a new and empty image grid.
  # == Parameters
  # [cell_width]
  #   The initial width of a single cell in pixels.
  # [cell_height]
  #   The initial height of a single cell in pixels.
  def initialize(cell_width, cell_height)
    super()
    @layers         = []
    @active_layer   = 0
    @layout         = Gtk::Layout.new

    @cell_width     = cell_width
    @cell_height    = cell_height
    @draw_grid      = false
    @alpha_layers   = 0.5
    @grid_color     = [0.5, 0, 1, 1]
    @mask           = []
    @button_is_down = false # Set to true while a mouse button is down
    @__first_cell_layer = nil

    @layout.set_size(*DEFAULT_SIZE)
    @layout.signal_connect(:expose_event, &method(:on_expose))
    add(@layout)

    @layout.add_events(Gdk::Event::BUTTON_PRESS_MASK | Gdk::Event::BUTTON_RELEASE_MASK | Gdk::Event::POINTER_MOTION_MASK)
    @layout.signal_connect(:button_press_event, &method(:on_button_press))
    @layout.signal_connect(:button_release_event, &method(:on_button_release))
    @layout.signal_connect(:motion_notify_event, &method(:on_motion))

    redraw!
  end

  # Human-readable description.
  def inspect
    "#<#{self.class} layers: #{@layers.count} active: #@active_layer tables: #{col_num}x#{row_num}>"
  end

  # Retrieves the Layer at the given Z position (or nil if there is none),
  # with 0 being the bottom layer. Negative values count from the top.
  def [](z)
    @layers[z]
  end

  # Replaces the Layer at the given Z position with a new one.
  def []=(z, layer)
    delete_layer(z)
    insert_layer(z, layer)
  end

  # The currently active Layer subclass instance, if any, otherwise
  # nil.
  def active_layer
    @layers[@active_layer]
  end

  # The index of the currently active layer.
  def active_layer_index
    @active_layer
  end

  # Set the index of the currently active layer. +z+ must be
  # an integer, directly setting a Layer subclass instance is
  # not allowed.
  def active_layer=(z)
    raise(RangeError, "Z index out of bounds: #{z} (must be between 0 and #{layer_num - 1}, both inclusive)") if z < 0 or z >= layer_num
    @active_layer = z
  end
  alias active_layer_index= active_layer=

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
    @layers.each{|l| l.cell_width = val if l.kind_of?(CellLayer)}
    redraw
  end

  # Adjust the height of all the cells. Automatically
  # redraws the canvas.
  def cell_height=(val)
    @cell_height = val
    @layers.each{|l| l.cell_height = val if l.kind_of?(CellLayer)}
    redraw
  end

  # Number of columns in the CellLayer layers.
  def col_num
    # FIXME: Use the caching from #canvas_size
    @layers.find{|l| l.kind_of?(CellLayer)}.col_num
  rescue NoMethodError
    0
  end

  # Number of rows in the CellLayer layers.
  def row_num
    # FIXME: Use the caching from #canvas_size
    @layers.find{|l| l.kind_of?(CellLayer)}.row_num
  rescue NoMethodError
    0
  end

  # Resize all CellLayers to the given number of columns.
  # See CellLayer#col_num= for more info.
  def col_num=(val)
    @layers.each{|l| l.col_num = val if l.kind_of?(CellLayer)}
  end

  # Resize all CellLayers to the given number of rows.
  # See CellLayer#row_num= for more info.
  def row_num=(val)
    @layers.each{|l| l.row_num = val if l.kind_of?(CellLayer)}
  end

  # Iterates over all cells in this grid and yields their
  # coressponding CellInfo and CellPos objects to the block.
  # +cell+ may be +nil+ for an empty cell. Non-cell layers
  # are ignored by this method.
  def each_table_cell
    @layers.each_with_index do |layer, z|
      next unless layer.kind_of?(CellLayer)

      layer.each_with_pos{|cell, pos| yield(cell, pos)}
    end
  end

  # Wipe out the internal array of layers. Does not affect
  # the mask.
  def clear
    @layers.clear
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
    if @layers.empty?
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

  # Calculates the width and height of the table by means of the
  # first CellLayer found in the table. Return value is a two-element array
  # of form <tt>[width, height]</tt> (both values are pixel values).
  # The results are cached as long as possible.
  def canvas_size
    # Note this code makes two
    # important assumptions: Each pixbuf has the same dimensions,
    # and the whole table is rectangular, i.e. no row has more columns
    # than another, etc.

    # @layers.find is a quite unperformant operation and #canvas_size
    # gets called really often in event handlers, so we try to
    # cache the result as long as possible (i.e. until the found Z
    # coordinate doesn’t refer to a CellLayer anymore. Note that we
    # don’t care if some other layer gets moved onto that Z as long as
    # this other layer is a CellLayer — all CellLayers in the table should
    # have the same dimensions.
    if !@__first_cell_layer || !@layers[@__first_cell_layer.z].kind_of?(CellLayer)
      @__first_cell_layer = @layers.find{|l| l.kind_of?(CellLayer)}
    end

    # Note we can’t cache the canvas size itself, because @cell_width, @cell_height and
    # the number of rows and columns in a layer can be changed dynamically.
    [@cell_width * @__first_cell_layer.col_num, @cell_height * @__first_cell_layer.row_num]
  rescue NoMethodError
    [0, 0] # No active layer = no layers = size is 0x0
  end

  # The number of layers in the table.
  def layer_num
    @layers.count
  end

  # Delete the layer at the given Z position; the
  # layers above that position are shifted down by one.
  # Does nothing if there is no layer at that position.
  # Negative values count from the end.
  def delete_layer(z)
    z = @layers.count + z if z < 0 # z is negative, hence + (-z) rather than - (-z)

    @layers.delete(z)

    # Don’t forget to tell the moved layers their new coordinate
    @layers[z..-1].each{|layer| layer.z -= 1}
  end

  # Resize all layers with cells at once securely
  # at will to the given number of columns (+width+),
  # rows (+height+), and even layers (+depth+, defaulting
  # to the current number of layers). Redraws the canvas.
  def resize_table!(width, height, depth = layer_num)
    self.layer_num = depth unless depth == layer_num

    @layers.each do |layer|
      layer.resize!(width, height)
    end

    redraw!
  end

  # Inserts the given Layer at Z index +z+. All higher
  # layers are shifted up by one. A +z+ of -1 appends
  # the layer onto the top of the layer stack.
  # A Z value greater than the number of currently available
  # layers causes a RangeError.
  def insert_layer(z, layer)
    raise(RangeError, "Z index #{z} out of bounds (#{@layers.count})!") if z > @layers.count
    @layers.insert(z, layer)

    # Don’t forget to tell the moved layers their new coordinate
    # (if a layer was appended at the top (z+1)..-1 would evaluate to
    # 0..-1 which is the entire array. As no Zs need to be changed
    # in that case anyway we just return.
    return if z == -1
    @layers[(z+1)..-1].each{|l| l.z += 1}
  end

  # Like #insert_layer, but directly inserts an empty CellLayer.
  def insert_cell_layer(z)
    insert_layer(z, CellLayer.new(z, col_num, row_num, @cell_width, @cell_height))
  end

  # Like #insert_layer, but directly inserts an empty PixelLayer.
  def insert_pixel_layer(z)
    insert_layer(z, PixelLayer.new(z))
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
    raise(KeyError, "Layer ##{z} is not a CellLayer") unless @layers[z].kind_of?(CellLayer)
    @mask.clear

    0.upto(col_num) do |y|
      0.upto(row_num) do |x|
        pos = CellPos.new(x, y, z, x * @cell_width, y * @cell_height)

        @mask << pos
      end
    end

    redraw
  end

  # Check if the layer +z+ is a CellLayer and if so, returns
  # the CellInfo at the specified position. Otherwise raises
  # a KeyError.
  def get_cell(x, y, z)
    layer = @layers[z]
    raise(KeyError, "Layer ##{z} ist not a CellLayer.") unless layer.kind_of?(CellLayer)

    layer[x, y]
  end

  # Check if the layer +z+ is a CellLayer and if so, sets the
  # specified cell to the given +value+ (the possible values
  # can be found in CellLayer#[]=). Otherwise raises a KeyError.
  def set_cell(x, y, z, value)
    layer = @layers[z]
    raise(KeyError, "Layer ##{z} ist not a CellLayer.") unless layer.kind_of?(CellLayer)

    layer[x, y] = value
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
      result = yield(pos, @layers[pos.cell_z][pos.cell_x, pos.cell_y])
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
    cc = @layout.bin_window.create_cairo_context

    # Allow the user to draw the background the way he likes
    signal_emit :draw_background,
                :cairo_context => cc,
                :event => event,
                :rectangle => Gdk::Rectangle.new(0, 0, col_num * @cell_width, row_num * @cell_height)

    # If there are no layers, we only need the background
    return if @layers.empty?

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
    @layers.each_with_index do |layer, z|
      layer.expose(cc,
                   Gdk::Rectangle.new(0, 0, col_num * @cell_width, row_num * @cell_height),
                   alpha: z > @active_layer && @alpha_layers <= 0.99 ? @alpha_layers : false)
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
      0.step(width, @cell_width) do |x|
        cc.move_to(x + 0.5, 0)
        cc.line_to(x + 0.5, height)
      end

      # Create the Cairo paths for the horizontal lines
      0.step(height, @cell_height) do |y|
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
    if active_layer.kind_of?(CellLayer)
      # Snap click coordinates to cell grid if the active layer is a CellLayer
      pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
      pos.x = pos.cell_x * @cell_width
      pos.y = pos.cell_y * @cell_height

      # Only care about clicks on the grid, not about those next to it
      return if pos.cell_x < 0 or pos.cell_x >= active_layer.col_num or pos.cell_y < 0 or pos.cell_y >= active_layer.row_num
    else
      # For other layers, hand the raw coordinates and ommit cell_x and cell_y
      pos = CellPos.new
      pos.cell_z = @active_layer
      pos.x = event.coords[0].to_i
      pos.y = event.coords[1].to_i

      # But still don’t care for clicks outside the grid
      return if pos.x < 0 or pos.x >= col_num * @cell_width or pos.y < 0 or pos.y >= row_num * @cell_height
    end

    @button_is_down = true
    signal_emit :cell_button_press, :pos => pos, :event => event
  end

  def on_motion(_, event)
    return unless @button_is_down

    # Snap click coordinates to cell grid if the active layer is a CellLayer
    if active_layer.kind_of?(CellLayer)
      pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
      pos.x = pos.cell_x * @cell_width
      pos.y = pos.cell_y * @cell_height

      # Only care about clicks on the grid, not about those next to it
      return if pos.cell_x < 0 or pos.cell_x >= active_layer.col_num or pos.cell_y < 0 or pos.cell_y >= active_layer.row_num
    else
      # For other layers, hand the raw coordinates and ommit cell_x and cell_y
      pos = CellPos.new
      pos.cell_z = @active_layer
      pos.x = event.coords[0].to_i
      pos.y = event.coords[1].to_i

      # But still don’t care for stuff outside the grid
      return if pos.x < 0 or pos.x >= col_num * @cell_width or pos.y < 0 or pos.y >= row_num * @cell_height
    end

    signal_emit :cell_button_motion, :pos => pos, :event => event
  end

  def on_button_release(_, event)
    return unless @button_is_down
    @button_is_down = false

    if active_layer.kind_of?(CellLayer)
      pos   = CellPos.new(event.coords[0].to_i / @cell_width, event.coords[1].to_i / @cell_height, @active_layer)
      pos.x = pos.cell_x * @cell_width
      pos.y = pos.cell_y * @cell_height

      # Don’t provide coordinates outside the cell grid
      pos = nil if pos.cell_x < 0 or pos.cell_x >= active_layer.col_num or pos.cell_y < 0 or pos.cell_y >= active_layer.row_num
    else
      pos = CellPos.new
      pos.cell_z = @active_layer
      pos.x = event.coords[0].to_i
      pos.y = event.coords[1].to_i

      # But still don’t care for stuff outside the grid
      pos = nil if pos.x < 0 or pos.x >= col_num * @cell_width or pos.y < 0 or pos.y >= row_num * @cell_height
    end

    signal_emit :cell_button_release, :event => event, :pos => pos
  end

end
