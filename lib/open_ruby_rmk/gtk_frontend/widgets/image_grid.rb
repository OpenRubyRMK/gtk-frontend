# -*- coding: utf-8 -*-
# This is a nested widget that can be used to draw grids of images and
# let the user interact with them. The images are internally stored as
# a two-dimensional array of Gdk::Pixbuf objects, each subarray representing
# a single row in the grid and each pixbuf a single cell.
#
# This widget consists basicly of two widgets: A Gtk::Layout, which
# is the canvas we draw the images onto and which may have an arbitrary
# size, and a Gtk::ScrolledWindow that acts as a scrollable container
# for the (possibly very large) canvas, so the user can scroll in order
# to see parts of the canvas otherwise flipping off the window or even
# the screen.
#
# When the widget is to be drawn, the internal array of Pixbuf instances
# is iterated, and each Pixbuf is then drawn onto the canvas according
# to its position in that array, representing a single cell. Note that
# the internal calculation of the size of the canvas depends on two
# things:
#
# 1. All Pixbufs you add to this widget must share the same dimensions.
#    This does not mean they have to be squared, but each pixbuf’s width
#    must be the same, and likewise each pixbuf’s height must also be the
#    same.
# 2. The internal pixbuf array must always represent a rectangle when
#    the widget is to be drawn, i.e. each row must have the same number
#    of cells. Use +nil+ instead of a pixbuf if you want to leave a
#    single cell blank.
#
# If you don’t obey these rules, you may experience weird effects when
# the widget is drawn.
#
# == Redrawing
# Whenever you change the underlying pixbuf array, that what is visible
# on the screen differs from the internal data. Therefore, whenever you
# change pixbuf information of this widget, call the #redraw! method
# afterwards so the visible part can be resynchronised with the internal
# data. This isn’t done automatically for you, because redrawing the
# widget each time you set something via #[]= in a loop is a severe
# performance hit. So instead, just do the entire loop and _then_ redraw
# the widget by ordering it to do so.
class OpenRubyRMK::GTKFrontend::Widgets::ImageGrid < Gtk::ScrolledWindow

  # The default size the unterlying canvas is set to when
  # the list of Pixbuf objects for this widget is empty
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
    @pixbufs = []
    @layout = Gtk::Layout.new

    @draw_grid = false
    @grid_color = [0.5, 0, 1, 1]

    @layout.set_size(*DEFAULT_SIZE)
    @layout.signal_connect(:expose_event, &method(:on_expose))
    add(@layout)

    @layout.add_events(Gdk::Event::BUTTON_PRESS_MASK | Gdk::Event::BUTTON_RELEASE_MASK)
    signal_connect(:button_press_event, &method(:on_button_press))
    signal_connect(:button_release_event, &method(:on_button_release))

    redraw!
  end

  # Set the Pixbuf instance at a specified coordinate. Use +nil+
  # for +pixbuf+ if you want an empty cell.
  def []=(x, y, pixbuf)
    0.upto(y){|i| @pixbufs[i] = [] unless @pixbufs[i]} unless @pixbufs[y]
    @pixbufs[y][x] = pixbuf
  end

  # Retrieves the Pixbuf instance (or +nil+) at the specified coordinate.
  def [](x, y)
    @pixbufs[y][x]
  end

  # Append an entire row of pixbufs to the bottom of the grid.
  def append_row(pixbufs)
    @pixbufs.push(pixbufs)
  end

  # Same as #append_row, but returns +self+ for method chaining.
  def <<(pixbufs)
    append_row
    self
  end

  # Replace the entire internal array with another. Be *very*
  # careful when using this method and re-read the notes on
  # the internal structure of that array in the class docs.
  def replace(pixbufs)
    @pixbufs.replace(pixbufs)
  end

  # Wipe out the internal array of pixbufs.
  def clear
    @pixbufs.clear
  end

  # True if the grid shall be drawn.
  def draw_grid?
    @draw_grid
  end

  # Recalculate the width and height of the canvas by examining
  # the stored Pixbuf objects (which must all have the same
  # dimensions and in total must sum up to a rectangular area)
  # and then redraw the entire widget. If the internal pixbuf
  # array is empty, resets the underlying canvas to the default
  # dimensions and redraws the widget.
  def redraw!
    if @pixbufs.empty?
      @layout.set_size(*DEFAULT_SIZE)
      @layout.queue_draw
      return
    end

    # Calculate the width and height of the underlying Cairo
    # context we will draw on.
    width, height = canvas_size

    # Tell GTK the new size and request a redraw.
    @layout.set_size(width, height)
    @layout.queue_draw
  end

  # Calculates the size of the underlying canvas by examining the
  # internal pixbuf array. Return value is a two-element array
  # of form <tt>[width, height]</tt> (both values are pixel values).
  def canvas_size
    # Note this code makes two
    # important assumptions: Each pixbuf has the same dimensions,
    # and the whole tabe is rectangular, i.e. no row has more columns
    # than another, etc.
    [tile_width * @pixbufs.first.count, tile_height * @pixbufs.count]
  end

  # The width of a single tile in pixels.
  def tile_width
    @pixbufs.first.first.width
  end

  # The height of a single tile in pixels.
  def tile_height
    @pixbufs.first.first.height
  end

  # The number of tile rows in the grid, i.e. how many tiles are
  # in a single column.
  def row_num
    @pixbufs.count
  end

  # The number of tile columns in the grid, i.e. how many tiles are
  # in a single row.
  def col_num
    col = @pixbufs.first
    return 0 unless col
    col.count
  end

  private

  def on_expose(_, event)
    return if @pixbufs.empty?
    cc = @layout.bin_window.create_cairo_context

    # TODO: Layers!
    # TODO: Instead of holding all the images in memory which
    # may consume extreme amounds depending on number of images,
    # fire a redraw_cell event here so the user can allocate the
    # image required for this cell temporarily.
    # TODO: Fire a redraw_layer event for non-grid layers.
    @pixbufs.each_with_index do |row, y|
      row.each_with_index do |pixbuf, x|
        next if pixbuf.nil? # Empty cell

        cc.set_source_pixbuf(pixbuf, x * pixbuf.width, y * pixbuf.height)
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
      0.step(width, @pixbufs.first.first.width) do |x|
        cc.move_to(x + 0.5, 0)
        cc.line_to(x + 0.5, height)
      end

      # Create the Cairo paths for the horizontal lines
      0.step(height, @pixbufs.first.first.height) do |y|
        cc.move_to(0, y + 0.5)
        cc.line_to(width, y + 0.5)
      end

      # Stroke the paths specified earlier with the requested colour.
      cc.set_source_rgba(*@grid_color)
      cc.line_width = 1
      cc.stroke
    end

    true # Event completely handled
  end

  def on_button_press(_, event)
    width, height = canvas_size
    x, y          = event.coords[0].to_i / tile_width, event.coords[1].to_i / tile_height

    # Only care about clicks on the map, not about those next to it
    return if x < 0 or x >= col_num or y < 0 or y >= row_num

    # TODO
  end

  def on_button_release(_, event)
    # TODO
  end

end
