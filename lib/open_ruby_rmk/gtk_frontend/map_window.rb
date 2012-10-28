# The window containing the map tree. Note that a MapWindow
# cannot be destroyed by the user; attempting to close it will
# effectively just hide the window, so it is easy to later
# re-display it.
class OpenRubyRMK::GTKFrontend::MapWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend

  # Creates a new MapWindow. Pass in the parent window you want
  # to make this window a helper window of.
  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint     = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title         = t.windows.map_tree.title

    setup_event_handlers
  end

  private

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
