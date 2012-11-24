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

    draw_prompt
  end

  private

  def create_widgets
    @terminal = Vte::Terminal.new
    @terminal.set_font("Monospace 14", Vte::TerminalAntiAlias::FORCE_ENABLE)
    # @terminal.fork_command("irb")
  end

  def create_layout
    add(@terminal)
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
    @terminal.signal_connect(:commit, &method(:on_commit))
  end

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  def on_commit(_, text, length)
    @cache << text
    @terminal.feed(text)

    if text.end_with?("\r")
      @terminal.feed("\nECHO: #@cache\n")
      @cache.clear
      draw_prompt
    end
  end

  ########################################
  # Helper methods

  def draw_prompt
    @terminal.feed(">>")
  end

end
