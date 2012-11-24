class OpenRubyRMK::GTKFrontend::ToolWindows::ConsoleWindow < Gtk::Window
  include Gtk

  def initialize(parent)
    super()
    set_default_size(400, 300)

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = "Debugging console"

    @cache = ""

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    @terminal = OpenRubyRMK::GTKFrontend::Widgets::RubyTerminal.new do
      on :enter do |line|
        "ECHO: #{line}\r\n"
      end
      on :prompt do
        ">> "
      end
    end
  end

  def create_layout
    add(@terminal)
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
