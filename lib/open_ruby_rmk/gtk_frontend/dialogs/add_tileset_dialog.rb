# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Dialogs::AddTilesetDialog < OpenRubyRMK::GTKFrontend::Dialogs::ResourceSelectionDialog

  validate do
    val_error t.dialogs.add_tileset.no_tileset_selected if !@directory_tree.selected_path or !@directory_tree.selected_path.file?
  end

  def initialize(map)
    @map = map
    super(t.dialogs.add_tileset.title, "tilesets", $app.mainwindow)
  end

  def create_preview_widget
    @image = Image.new
  end

  def get_preview_widget
    ScrolledWindow.new.tap do |scroller|
      scroller.add_with_viewport(@image)
    end
  end

  def handle_accept(selected_path)
    tileset = TiledTmx::Tileset.load_xml(selected_path)
    @map.add_tileset(tileset)
  end

  def handle_cursor_changed(selected_path)
    tileset = TiledTmx::Tileset.load_xml(@directory_tree.selected_path)
    @image.pixbuf = Gdk::Pixbuf.new(tileset.source.to_s)
  end

end
