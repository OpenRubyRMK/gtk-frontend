# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapGrid < OpenRubyRMK::GTKFrontend::Widgets::ImageGrid
  include OpenRubyRMK::Backend::Eventable

  TileInfo = Struct.new(:x, :y, :layer, :tileset, :tileset_x, :tileset_y) do
    # Two tile infos are considered equal if all their
    # attributes except for :x and :y are equal.
    def ==(other) # :nodoc:
      other.layer == layer && other.tileset == tileset &&
        other.tileset_x == tileset_x && other.tileset_y == tileset_y
    end
  end

  def initialize
    super
    @map = nil
    @tileset_pixbufs = {}
    @first_selection = nil

    signal_connect(:cell_button_press, &method(:on_cell_button_press))
    signal_connect(:cell_button_motion, &method(:on_cell_button_motion))
    signal_connect(:cell_button_release, &method(:on_cell_button_release))
  end

  # Change the currently displayed map to another one, clearing
  # all internal graphic buffers, reloading them from disk and
  # finally redrawing the entire widget.
  # == Events
  # [map_changed]
  #   Always emitted when this method is called. Callback
  #   receives +map+ via the :map parameter.
  def map=(map)
    changed

    @map = map
    @tileset_pixbufs.clear

    # Preload all tileset images, so we don’t have to do this
    # when rendering.
    @map.tmx_map.tilesets.each_value do |tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end

    clear
    # Iterate over all map layers bottom to top, so upper layers get drawn
    # above lower ones. Note that the Pixbuf instanciation below is actually
    # a clipping operation on the tileset Pixbuf, and therefore a very fast
    # operation.
    # TODO: Depending on the active layer, set alpha on higher layers?
    @map.tmx_map.layers.each do |layer|
      layer.each_tile(@map.tmx_map) do |mapx, mapy, tile, id, tileset, flips|
        # Convert the relative tile ID into coordinates on the tileset pixmap
        tx, ty, x, y = tileset.tile_position(id)

        # Extract the tile from the tileset pixmap and store it in
        # the widget’s drawing storage.
        set_cell(mapx,
                 mapy,
                 Gdk::Pixbuf.new(@tileset_pixbufs[tileset],
                                 x,
                                 y,
                                 tileset.tilewidth,
                                 tileset.tileheight),
                 TileInfo.new(mapx, mapy, layer, tileset, tx, ty))
      end
    end

    redraw!
    notify_observers(:map_changed, :map => map)
  end

  private

  ########################################
  # Event handlers

  def on_cell_button_press(_, hsh)
    return unless @map

    @pressed_button = hsh[:event].button
    return unless hsh[:event].button == 3 # Secondary mouse button

    clear_mask
    add_to_mask(hsh[:pos])
    @first_selection = hsh[:pos]
  end

  def on_cell_button_motion(_, hsh)
    return unless @map
    return unless @pressed_button == 3 # Secondary mouse button

    # Mask adjustments for those selection modes that are motion-aware
    case $app.mainwindow.tileset_window.selection_mode
      when :rectangle then mask_rectangle(@first_selection, hsh[:pos])
      when :freehand  then add_to_mask(hsh[:pos])
    end
  end

  def on_cell_button_release(_, hsh)
    return unless @map
    return unless hsh[:pos]
    return unless @pressed_button == hsh[:event].button # Shouldn’t happen

    # Mask adjustments for those selection modes that aren’t motion-aware
    case $app.mainwindow.tileset_window.selection_mode
      when :magic then mask_adjascent(@first_selection)
    end

    case @pressed_button
    when 1 then # Primary mouse button
      fill_mask
    when 3 then # Secondary mouse button
      @first_selection = nil
    when 2 then # Middle mouse button
      # TODO: Something useful?
    end
  end

  ########################################
  # Helpers

  # Fills the current mask with the selected tileset’s
  # selected tile, afterwards clears the mask.
  def fill_mask
    tiles = $app.mainwindow.tileset_window.tileset_grid.selection
    return unless tiles # No tile selected
    tile = tiles.first  # Only one tile can actually be selected

    selection.each do |cell_info|
      # By-reference is great :-)
      # Just update the layer and pixbuf referenced by this cell,
      # and redraw the canvas — everything done! When the map
      # gets saved, everything where it ought to be thanks
      # to this.
      index = cell_info.data.layer.pos2index(@map.tmx_map, cell_info.data.x, cell_info.data.y)
      cell_info.data.layer[index] = tile.data[:gid]
      # It should be possible to do this without dupping, but I don’t
      # feel good if two entirely separate widgets hold references
      # to the same image...
      cell_info.pixbuf = tile.pixbuf.dup
    end

    clear_mask # Issues #redraw itself
  end

end
