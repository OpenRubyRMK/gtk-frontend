class OpenRubyRMK::GTKFrontend::Widgets::MapTable < Gtk::DrawingArea

  def initialize
    super
    @map = nil

    set_size_request(32, 32)
    signal_connect(:expose_event, &method(:on_expose))
  end

  def map=(map)
    @map = map
    #TODO: Redraw whole widget area!
  end

  private

  def on_expose(_, event)
    gc = Gdk::GC.new(window)
    gc.rgb_fg_color = Gdk::Color.new(50000, 0, 0)
    window.draw_rectangle(gc, true, 0, 0, allocation.width, allocation.height)

    true
  end

end
