# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Dialogs::AddTilesetDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Validatable

  validate do
    val_error "No tileset selected." if !@directory_tree.selected_path or !@directory_tree.selected_path.file?
  end

  def initialize(map)
    super("Add tileset",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 500, 300
    @map = map

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @directory_tree = OpenRubyRMK::GTKFrontend::Widgets::DirectoryTreeView.new($app.project.paths.data_dir + "tilesets", true)
    @image          = Image.new
  end

  def create_layout
    HBox.new.tap do |hbox|
      hbox.pack_start(@directory_tree, false)
      ScrolledWindow.new.tap do |scroller|
        scroller.add_with_viewport(@image)

        hbox.pack_start(scroller, true)
      end

      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @directory_tree.signal_connect(:cursor_changed, &method(:on_cursor_changed))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      $app.warnbox(validation_summary) and return unless valid?
      # TODO
    end

    destroy
  end

  def on_cursor_changed(*)
    @image.pixbuf = nil
    return unless @directory_tree.selected_path
    return unless @directory_tree.selected_path.file?

    tileset = TiledTmx::Tileset.load_xml(@directory_tree.selected_path)
    @image.pixbuf = Gdk::Pixbuf.new(tileset.source.to_s)
  end

end
