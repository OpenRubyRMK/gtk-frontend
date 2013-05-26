# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapGrid < OpenRubyRMK::GTKFrontend::Widgets::ImageGrid

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

    $app.state[:core].observe(:value_set) do |event, sender, info|
      case info[:key]
      when :map     then update_map(info[:value])
      when :z_index then
        self.active_layer = info[:value]
        redraw!
      end
    end
  end

  private

  ########################################
  # Event handlers

  def on_cell_button_press(_, hsh)
    return unless @map

    if active_layer.kind_of?(CellLayer)
      @pressed_button = hsh[:event].button
      return unless hsh[:event].button == 3 # Secondary mouse button

      clear_mask
      add_to_mask(hsh[:pos])
      @first_selection = hsh[:pos]
    end
  end

  def on_cell_button_motion(_, hsh)
    return unless @map
    return unless @pressed_button == 3 # Secondary mouse button

    if active_layer.kind_of?(CellLayer)
      # Mask adjustments for those selection modes that are motion-aware
      case $app.state[:core][:selection_mode]
      when :rectangle then mask_rectangle(@first_selection, hsh[:pos])
      when :freehand  then add_to_mask(hsh[:pos])
      end
    end
  end

  def on_cell_button_release(_, hsh)
    return unless @map
    return unless hsh[:pos]
    return unless @pressed_button == hsh[:event].button # Shouldn’t happen

    if active_layer.kind_of?(CellLayer)
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

  # Change the currently displayed map to another one, clearing
  # all internal graphic buffers, reloading them from disk and
  # finally redrawing the entire widget.
  def update_map(map)
    @map = map
    @tileset_pixbufs.clear
    self.cell_width  = @map.tmx_map.tilewidth
    self.cell_height = @map.tmx_map.tileheight

    # Preload all tileset images, so we don’t have to do this
    # when rendering.
    @map.tmx_map.each_tileset do |first_gid, tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end

    clear_mask
    clear

    # Iterate over all map layers bottom to top, so upper layers get drawn
    # above lower ones. Note that the Pixbuf instanciation below is actually
    # a clipping operation on the tileset Pixbuf, and therefore a very fast
    # operation.
    @map.tmx_map.each_layer.with_index do |layer, mapz|
      if layer.kind_of?(TiledTmx::TileLayer)
        insert_cell_layer(mapz)

        layer.each_tile do |mapx, mapy, tile, id, tileset, flips|
          if tileset
            # Convert the relative tile ID into coordinates on the tileset pixmap
            x, y  = tileset.tile_position(id)

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
      elsif layer.kind_of?(TiledTmx::ObjectGroup)
        insert_object_layer(mapz)
        # FIXME
      elsif layer.kind_of?(TiledTmx::ImageLayer)
        insert_object_layer(mapz)
        # FIXME
      else
        raise("Unsupported layer type: #{layer.class}")
      end
    end

    # New layers are always empty and are always appended
    # to the top of the current Z layers, i.e. the new layer
    # is always the topmost one. Therefore, whenever a new
    # layer is added, we just append an empty one to the
    # image grid at the end (-1). Cell setting is not
    # necessary, because the new layer is guaranteed to
    # be empty, and insert_layer already creates an empty
    # layer.
    @map.observe(:layer_added) do |event, sender, info|
      case info[:layer]
      when TiledTmx::TileLayer then insert_cell_layer(-1)
      when TiledTmx::ObjectGroup then insert_pixel_layer(-1)
      when TiledTmx::ImageLayer then insert_pixel_layer(-1)
      else
        raise("Unsupported layer type: #{info[:layer].class}")
      end

      redraw
    end

    # When the map size is changed, we definitely need to
    # redraw the map grid.
    @map.observe(:size_changed) do |event, sender, info|
      self.col_num = info[:size][0]
      self.row_num = info[:size][1]

      redraw!
    end

    redraw!
  end

  # Fills the current mask with the selected tileset’s
  # selected tile, afterwards clears the mask.
  def fill_mask
    apply! do |cell_pos, cell_info|
      return unless $app.state[:core][:brush_gid]
      return unless $app.state[:core][:brush_pixbuf]

      # FIXME: When ruby-tmx provides a possibility to calculate
      # the tile index from the pixel position, use that method
      # instead of calculating this ourself. Note that the
      # following calculation does ONLY work for tilesets
      # WITHOUT spacing and the-like!
      index = cell_pos.cell_x + @map.tmx_map.width * cell_pos.cell_y

      layer        = @map.tmx_map.get_layer(cell_pos.cell_z)
      layer[index] = $app.state[:core][:brush_gid]

      # Instruct ImageGrid to replace this cell’s pixbuf
      # with the pixbuf for the respective tile on the tileset.
      $app.state[:core][:brush_pixbuf].dup
    end
  end

end
