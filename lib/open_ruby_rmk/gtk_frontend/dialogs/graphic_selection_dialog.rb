class OpenRubyRMK::GTKFrontend::Dialogs::GraphicSelectionDialog < OpenRubyRMK::GTKFrontend::Dialogs::ResourceSelectionDialog

  validate do
    val_error "No graphic selected" if !@directory_tree.selected_path or !@directory_tree.selected_path.file?
  end

  def initialize(parent)
    super("Select a graphic", "resources/graphics", parent)
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
    @image.pixbuf = Gdk::Pixbuf.new(selected_path.to_s)
  end

end
