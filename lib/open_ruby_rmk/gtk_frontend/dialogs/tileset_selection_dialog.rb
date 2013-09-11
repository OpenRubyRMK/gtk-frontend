# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Dialogs::TilesetSelectionDialog < OpenRubyRMK::GTKFrontend::Dialogs::ResourceSelectionDialog

  validate do
    val_error t.dialogs.select_tileset.no_tileset_selected if !@directory_tree.selected_path or !@directory_tree.selected_path.file?
  end

  def initialize(parent)
    super(t.dialogs.add_tileset.title, "tilesets", parent)
  end

  def create_preview_widget
    @image = Image.new
  end

  def get_preview_widget
    ScrolledWindow.new.tap do |scroller|
      scroller.add_with_viewport(@image)
    end
  end

  def handle_cursor_changed(selected_path)
    tileset = TiledTmx::Tileset.load_xml(selected_path)
    @image.pixbuf = Gdk::Pixbuf.new(tileset.source.to_s)
  end

end
