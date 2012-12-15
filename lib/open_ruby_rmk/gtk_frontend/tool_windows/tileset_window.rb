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
    @toolbar           = Toolbar.new
    @rect_mode_button  = RadioToolButton.new(nil, :orr_rectangle_selection)
    @magic_mode_button = RadioToolButton.new(@rect_mode_button, :orr_magic_selection)
    @free_mode_button  = RadioToolButton.new(@rect_mode_button, :orr_freehand_selection)

    [@free_mode_button, @magic_mode_button, @rect_mode_button].each do |button|
      @toolbar.insert(0, button)
    end

    @tileset_grid            = OpenRubyRMK::GTKFrontend::Widgets::ImageGrid.new
    @tileset_grid.draw_grid  = true
    @rect_mode_button.active = true
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
    @tileset_grid.signal_connect(:cell_button_release, &method(:on_cell_button_release))
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

      0.upto(Float::INFINITY) do |id|
        pos = tileset.tile_position(id)
        break unless pos

        @tileset_grid.set_cell(pos[0], pos[1], Gdk::Pixbuf.new(tileset_pixbuf, pos[2], pos[3], tileset.tilewidth, tileset.tileheight))
      end
    end


    @tileset_grid.redraw!
  end
  public :map_grid_changed # For Observable

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  def on_cell_button_release(_, hsh)
    return unless hsh[:pos]

    @tileset_grid.clear_mask
    @tileset_grid.add_to_mask(hsh[:pos])
  end

end
