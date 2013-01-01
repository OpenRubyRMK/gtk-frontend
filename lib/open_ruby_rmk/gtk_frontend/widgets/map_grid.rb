# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapGrid < OpenRubyRMK::GTKFrontend::Widgets::ImageGrid
  include OpenRubyRMK::Backend::Eventable

  # Creates a new instance. All arguments are forwarded to ImageGrid::new.
  def initialize(*)
    super
    @map = nil
    @tileset_pixbufs = {}
    @first_selection = nil

    signal_connect(:cell_button_press, &method(:on_cell_button_press))
    signal_connect(:cell_button_motion, &method(:on_cell_button_motion))
    signal_connect(:cell_button_release, &method(:on_cell_button_release))
    signal_connect(:draw_background, &method(:on_draw_background))
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
    $app.state[:core][:map] = @map
    @tileset_pixbufs.clear
    self.cell_width  = @map.tmx_map.tilewidth
    self.cell_height = @map.tmx_map.tileheight

    # Preload all tileset images, so we don’t have to do this
    # when rendering.
    @map.tmx_map.tilesets.each_value do |tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end

    clear_mask
    clear

    # Iterate over all map layers bottom to top, so upper layers get drawn
    # above lower ones. Note that the Pixbuf instanciation below is actually
    # a clipping operation on the tileset Pixbuf, and therefore a very fast
    # operation.
    # TODO: Depending on the active layer, set alpha on higher layers?
    @map.tmx_map.layers.each_with_index do |layer, mapz|
      layer.each_tile(@map.tmx_map) do |mapx, mapy, tile, id, tileset, flips|
        if tileset
          # Convert the relative tile ID into coordinates on the tileset pixmap
          tx, ty, x, y  = tileset.tile_position(id)

          # Extract the tile from the tileset pixmap and store it in
          # the widget’s drawing storage.
          set_cell(mapx,
                   mapy,
                   mapz,
                   Gdk::Pixbuf.new(@tileset_pixbufs[tileset],
                                   x,
                                   y,
                                   tileset.tilewidth,
                                   tileset.tileheight))
        else # Empty cell
          set_cell(mapx, mapy, mapz, nil)
        end
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
    case $app.state[:core][:selection_mode]
      when :rectangle then mask_rectangle(@first_selection, hsh[:pos])
      when :freehand  then add_to_mask(hsh[:pos])
    end
  end

  def on_cell_button_release(_, hsh)
    return unless @map
    return unless hsh[:pos]
    return unless @pressed_button == hsh[:event].button # Shouldn’t happen

    # Mask adjustments for those selection modes that aren’t motion-aware
    case $app.state[:core][:selection_mode]
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

  # We clear to a black background by default
  def on_draw_background(_, hsh)
    cc = hsh[:cairo_context]
    rect = hsh[:rectangle]

    cc.rectangle(rect.x, rect.y, rect.width, rect.height)
    cc.set_source_rgb(0, 0, 0)
    cc.fill
  end

  ########################################
  # Helpers

  # Fills the current mask with the selected tileset’s
  # selected tile, afterwards clears the mask.
  def fill_mask
    apply! do |cell_pos, cell_info|
      return unless $app.state[:core][:brush_gid]
      return unless $app.state[:core][:brush_pixbuf]

      layer        = @map.tmx_map.layers[cell_pos.cell_z]
      index        = layer.pos2index(@map.tmx_map, cell_pos.cell_x, cell_pos.cell_y)
      layer[index] = $app.state[:core][:brush_gid]

      # Instruct ImageGrid to replace this cell’s pixbuf
      # with the pixbuf for the respective tile on the tileset.
      $app.state[:core][:brush_pixbuf].dup
    end
  end

end
