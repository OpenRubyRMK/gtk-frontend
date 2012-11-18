# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapTable < Gtk::ScrolledWindow

  # Creates a new instance of this class.
  def initialize
    super
    @map = nil
    @tileset_pixbufs = {}

    @layout = Gtk::Layout.new

    @layout.set_size(32, 32) # Dummy start size
    @layout.signal_connect(:expose_event, &method(:on_expose))
    add(@layout)
  end

  # Change the currently displayed map to another one, clearing
  # all internal graphic buffers, reloading them from disk and
  # finally redrawing the entire widget.
  def map=(map)
    @map = map
    @tileset_pixbufs.clear

    # Preload all tileset images, so we don’t have to do this
    # when rendering.
    @map.tmx_map.tilesets.each_value do |tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end

    # Request the underlying drawing canvas to be redrawn.
    @layout.queue_draw
  end

  private

  def on_expose(_, event)
    return unless @map
    cc = @layout.bin_window.create_cairo_context

    # Iterate over all map layers bottom to top, so upper layers get drawn
    # above lower ones. Note that the Pixbuf instanciation below is actually
    # a clipping operation on the tileset Pixbuf, and therefore a very fast
    # operation.
    @map.tmx_map.layers.each do |layer|
      layer.each_tile(@map.tmx_map) do |lx, ly, tile, id, tileset, flips|
        # Convert the relative tile ID into coordinates on the tileset pixmap
        x, y = tileset.tile_position(id)

        # Extract the tile from the tileset pixmap and store it in
        # Cairo’s drawing buffer.
        cc.set_source_pixbuf(Gdk::Pixbuf.new(@tileset_pixbufs[tileset], x, y, tileset.tilewidth, tileset.tileheight),
                             lx * tileset.tilewidth,
                             ly * tileset.tileheight)

        # Print out Cairo’s drawing buffer.
        cc.paint
      end
    end

    # Event completely handled.
    true
  end

end
