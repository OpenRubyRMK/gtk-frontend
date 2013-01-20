class OpenRubyRMK::GTKFrontend::ToolWindows::LayerWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend

  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = "Layers"

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
  end

  def create_layout
  end

  def setup_event_handlers
  end

end
