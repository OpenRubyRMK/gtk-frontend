class OpenRubyRMK::GTKFrontend::ToolWindows::TilesetWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = "Tileset"

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    @toolbar = Toolbar.new
    @paint_mode_button = ToggleToolButton.new(:paint_mode)
    @fill_mode_button  = ToggleToolButton.new(:fill_mode)

    @toolbar.insert(0, @paint_mode_button)
    @toolbar.insert(0, @fill_mode_button)

    @tileset_area = DrawingArea.new
  end

  def create_layout
    VBox.new.tap do |vbox|

      vbox.pack_start(@toolbar, false)
      vbox.pack_start(@tileset_area, true, true)

      add(vbox)
    end
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  ########################################
  # Event handlers

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
