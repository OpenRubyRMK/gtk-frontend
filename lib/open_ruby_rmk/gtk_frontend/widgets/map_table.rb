class OpenRubyRMK::GTKFrontend::Widgets::MapTable < Gtk::ScrolledWindow

  def initialize
    super
    @map = nil
    @tileset_pixbufs = {}

    @layout = Gtk::Layout.new

    set_size_request(500, 400)
    @layout.set_size(800, 800)
    @layout.signal_connect(:expose_event, &method(:on_expose))

    add(@layout)
  end

  def map=(map)
    @map = map
    @tileset_pixbufs.clear

    @map.tmx_map.tilesets.each do |tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end
  end

  private

  def on_expose(_, event)
    #return unless @map
    cc = @layout.bin_window.create_cairo_context

    m = TiledTmx::Map.load_xml("/home/quintus/repos/privat/projekte/ruby/OpenRubyRMK/backend/data/skeleton/data/maps/0001.tmx")
    pf = Gdk::Pixbuf.new(m.tilesets[1].source.to_s)

    m.layers.each do |layer|
      layer.each_tile(m) do |lx, ly, tile, id, tileset, flips|
        x, y = tileset.tile_position(id)

        cc.set_source_pixbuf(Gdk::Pixbuf.new(pf, x, y, tileset.tilewidth, tileset.tileheight),
                             lx * tileset.tilewidth,
                             ly * tileset.tileheight)
        cc.paint
      end
    end

    true
  end

end
