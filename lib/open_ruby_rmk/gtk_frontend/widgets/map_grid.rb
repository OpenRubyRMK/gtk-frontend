# -*- coding: utf-8 -*-

# This is the widget that displays the map on the main window.
class OpenRubyRMK::GTKFrontend::Widgets::MapGrid < OpenRubyRMK::GTKFrontend::Widgets::ImageGrid
  include OpenRubyRMK::Backend::Eventable

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
        self[mapx, mapy] = Gdk::Pixbuf.new(@tileset_pixbufs[tileset], x, y, tileset.tilewidth, tileset.tileheight)
      end
    end

    redraw!
    notify_observers(:map_changed, :map => map)
  end

  private

  ########################################
  # Event handlers

  def on_cell_button_press(_, hsh)
    clear_selection
    add_to_selection(hsh[:pos])
    @first_selection = hsh[:pos]
  end

  def on_cell_button_motion(_, hsh)
    select_rectangle(@first_selection, hsh[:pos])
  end

  def on_cell_button_release(_, hsh)
    @first_selection = nil
  end


end
