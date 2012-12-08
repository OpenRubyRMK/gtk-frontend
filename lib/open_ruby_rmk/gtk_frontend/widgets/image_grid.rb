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

  def initialize
    super
    @pixbufs = []
    @layout = Gtk::Layout.new

    @layout.set_size(*DEFAULT_SIZE)
    @layout.signal_connect(:expose_event, &method(:on_expose))
    add(@layout)

    redraw!
  end

  def []=(x, y, pixbuf)
    0.upto(y){|i| @pixbufs[i] = [] unless @pixbufs[i]} unless @pixbufs[y]
    @pixbufs[y][x] = pixbuf
  end

  def [](x, y)
    @pixbufs[y][x]
  end

  def append_row(pixbufs)
    @pixbufs.push(pixbufs)
  end

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
    # context we will draw on. Note this code makes two
    # important assumptions: Each pixbuf has the same dimensions,
    # and the whole tabe is rectangular, i.e. no row has more columns
    # than another, etc.
    width  = @pixbufs.first.first.height * @pixbufs.first.count
    height = @pixbufs.first.first.width * @pixbufs.count

    # Tell GTK the new size and request a redraw.
    @layout.set_size(width, height)
    @layout.queue_draw
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

    true # Event completely handled
  end

end
