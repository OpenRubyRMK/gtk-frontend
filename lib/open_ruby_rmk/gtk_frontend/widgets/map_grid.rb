# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapGrid < OpenRubyRMK::GTKFrontend::Widgets::ImageGrid
  include R18n::Helpers

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

    @pressed_button = hsh[:event].button
    if active_layer.kind_of?(CellLayer)
      return unless hsh[:event].button == 3 # Secondary mouse button

      clear_mask
      add_to_mask(hsh[:pos])
    end

    @first_selection = hsh[:pos]
  end

  def on_cell_button_motion(_, hsh)
    return unless @map

    if active_layer.kind_of?(CellLayer)
      return unless @pressed_button == 3 # Secondary mouse button
      # Mask adjustments for those selection modes that are motion-aware
      case $app.state[:core][:selection_mode]
      when :rectangle then mask_rectangle(@first_selection, hsh[:pos])
      when :freehand  then add_to_mask(hsh[:pos])
      end
    elsif active_layer.kind_of?(PixelLayer)
      ## Ignore ImageLayers, there are no actions one could apply to them
      #return unless @map.get_layer($app.state[:core][:z_index]).kind_of?(TiledTmx::ObjectGroup)
    end
  end

  def on_cell_button_release(_, hsh)
    return unless @map
    return unless hsh[:pos]
    return unless @pressed_button == hsh[:event].button # Shouldn’t happen

    if active_layer.kind_of?(CellLayer)
      handle_cell_layer_button_release(hsh)

    elsif active_layer.kind_of?(PixelLayer)
      # Ignore ImageLayers, there are no actions one could apply to them
      return unless @map.get_layer(hsh[:pos].cell_z).kind_of?(TiledTmx::ObjectGroup)

      handle_object_layer_button_release(hsh)
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
    self.cell_width  = @map.tilewidth
    self.cell_height = @map.tileheight

    # Preload all tileset images, so we don’t have to do this
    # when rendering.
    @map.each_tileset do |first_gid, tileset|
      @tileset_pixbufs[tileset] = Gdk::Pixbuf.new(tileset.source.to_s)
    end

    clear_mask
    clear

    # Iterate over all map layers bottom to top, so upper layers get drawn
    # above lower ones. Note that the Pixbuf instanciation below is actually
    # a clipping operation on the tileset Pixbuf, and therefore a very fast
    # operation.
    @map.each_layer.with_index do |layer, mapz|
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
        insert_pixel_layer(mapz)

        layer.objects.each do |obj|
          add_pixel_object(mapz, obj.x, obj.y, obj.width, obj.height, :object => obj)
        end
      elsif layer.kind_of?(TiledTmx::ImageLayer)
        insert_pixel_layer(mapz)
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
      index = cell_pos.cell_x + @map.width * cell_pos.cell_y

      layer        = @map.get_layer(cell_pos.cell_z)
      layer[index] = $app.state[:core][:brush_gid]

      # Instruct ImageGrid to replace this cell’s pixbuf
      # with the pixbuf for the respective tile on the tileset.
      $app.state[:core][:brush_pixbuf].dup
    end
  end

  # Add an object (on a PixelLayer) to the map and the widget.
  # +type+ is the type of the object (a symbol or string),
  # +name+ the actual name you want.
  def add_object(type, x, y, z, width, height)
    # Create it
    obj = TiledTmx::Object.new(type: type.to_s, x: x, y: y, width: width, height: height)

    # Add it to the underlying map
    @map.add_object(z, obj)

    # Add it to the widget
    add_pixel_object(z, x, y, width, height, :object => obj)
  end

  def handle_cell_layer_button_release(hsh)
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

  def handle_object_layer_button_release(hsh)
    case $app.state[:core][:objects_mode]
    when :character then handle_character_button_release(hsh)
    when :free      then handle_free_button_release(hsh)
    when :edit      then handle_edit_button_release(hsh)
    end
  end

  def handle_character_button_release(hsh)
    x, y, z, width, height = hsh[:pos].x, hsh[:pos].y, hsh[:pos].cell_z, self.cell_width, self.cell_height

    if $app.state[:core][:template]
      add_object($app.state[:core][:template].name, x, y, z, width, height)
      redraw_area(x, y, width, height)
    else
      add_object(OpenRubyRMK::Backend::MapObject::GENERIC_OBJECT_TYPENAME, x, y, z, width, height)
      redraw_area(x, y, width, height)
    end
  end

  def handle_free_button_release(hsh)
    # FIXME (use hsh[:event]) for the real coords
  end

  def handle_edit_button_release(hsh)
    x, y = *hsh[:event].coords

    target = active_layer.find{ |obj| (x >= obj.x && y >= obj.y) && (x < obj.x + obj.width && y < obj.y + obj.height) }

    if target
      if target.info[:object].type == OpenRubyRMK::Backend::MapObject::GENERIC_OBJECT_TYPENAME
        ed = OpenRubyRMK::GTKFrontend::Dialogs::EventDialog.new(target.info[:object])
        ed.run
      else
        begin
          td = OpenRubyRMK::GTKFrontend::Dialogs::TemplateEventDialog.new(target.info[:object])
          td.run
        rescue OpenRubyRMK::GTKFrontend::Errors::UnknownTemplate => e
          $app.warnbox(sprintf(t.dialogs.template_event.template_not_found, :identifier => e.identifier))
        end #begin/rescue
      end
    end #if target
  end

end
