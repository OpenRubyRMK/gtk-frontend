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

    parent.map_grid.add_observer(self, :map_grid_changed)

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    @toolbar = Toolbar.new
    @paint_mode_button = RadioToolButton.new(nil, :orr_paint_mode)
    @fill_mode_button  = RadioToolButton.new(@paint_mode_button, :orr_fill_mode)

    @toolbar.insert(0, @paint_mode_button)
    @toolbar.insert(0, @fill_mode_button)

    @tileset_grid = OpenRubyRMK::GTKFrontend::Widgets::ImageGrid.new
  end

  def create_layout
    VBox.new.tap do |vbox|

      vbox.pack_start(@toolbar, false)
      vbox.pack_start(@tileset_grid, true, true)

      add(vbox)
    end
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  ########################################
  # Event handlers

  def map_grid_changed(event, sender, info)
    return unless event == :map_changed
    @tileset_grid.clear

    if info[:map] and !info[:map].tmx_map.tilesets.empty?
      # TODO: Support multiple tilesets in tabs!
      start_id       = info[:map].tmx_map.tilesets.keys.first
      tileset        = info[:map].tmx_map.tilesets[start_id]
      tileset_pixbuf = Gdk::Pixbuf.new(tileset.source.to_s)

      0.upto(Float::INFINITY) do |id| # First tileset tile index is always 1, not 0
        pos = tileset.tile_position(id)
        break unless pos

        @tileset_grid[pos[0], pos[1]] = Gdk::Pixbuf.new(tileset_pixbuf, pos[2], pos[3], tileset.tilewidth, tileset.tileheight)
      end
    end


    @tileset_grid.redraw!
  end
  public :map_grid_changed # For Observable

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
