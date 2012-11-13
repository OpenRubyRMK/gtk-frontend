class OpenRubyRMK::GTKFrontend::Widgets::MapTable < Gtk::ScrolledWindow

  def initialize
    super
    @map = nil

    @layout = Gtk::Layout.new

    set_size_request(500, 400)
    @layout.set_size(800, 800)
    @layout.signal_connect(:expose_event, &method(:on_expose))

    add(@layout)
  end

  def map=(map)
    @map = map
    #TODO: Redraw whole widget area!
  end

  private

  def on_expose(_, event)
    gc = Gdk::GC.new(@layout.bin_window)
    gc.rgb_fg_color = Gdk::Color.new(50000, 0, 0)
    gc2 = Gdk::GC.new(@layout.bin_window)
    gc2.rgb_fg_color = Gdk::Color.new(0, 50000, 0)

    gcs = [gc, gc2].cycle

    0.step(@layout.size[0], 10) do |x|
      @layout.bin_window.draw_rectangle(gcs.next, true, x, 0, 10, @layout.size[1])
    end


    true
  end

end
