# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Widgets::TilesetBook < Gtk::Notebook
  type_register
  signal_new :selection_changed, GLib::Signal::RUN_FIRST, nil, nil, Hash

  TilesetTileInfo = Struct.new(:tileset, :tile)

  def initialize
    super
    @map = nil
    @pagenum2tileset = []
  end

  def map=(map)
    clear
    @map = map
    return unless @map # Allow setting to nil

    # Add tabs for all tilesets we have *now*
    map.tmx_map.each_tileset do |start_id, tileset|
      add_tileset_tab(start_id, tileset)
    end

    # And listen to the map for those we get *later*
    @map.observe(:tileset_added) do |event, sender, hsh|
      add_tileset_tab(hsh[:gid], hsh[:tileset])
      show_all
    end

    show_all
  end

  def map
    @map
  end

  def selected_tileset
    return nil unless @map # No map
    return nil if page < 0 # No tilesets

    @pagenum2tileset[page]
  end

  def selected_tileset_tile
    return nil unless @map
    return nil if page < 0

    masked_tiles = get_nth_page(page).selection
    return nil if !masked_tiles or masked_tiles.empty?
    result = TilesetTileInfo.new
    result.tileset = @pagenum2tileset[page]
    result.tile = masked_tiles.first # Only one tile can be masked at all

    result
  end

  private

  def signal_do_selection_changed(*)

  end

  # Removes all pages from this tabbook (but does *not*
  # alter the underlying map!).
  def clear
    n_pages.times{remove_page(-1)}
  end

  # Add a tab for the TiledTmx::Tileset starting at the
  # GID +start_id+ to the tabbook.
  def add_tileset_tab(start_id, tileset)
    # Create the widget and the pixbuf for the
    # entire tileset image.
    tileset_pixbuf = Gdk::Pixbuf.new(tileset.source.to_s)
    tileset_grid   = OpenRubyRMK::GTKFrontend::Widgets::ImageGrid.new(@map.tmx_map.tilewidth, @map.tmx_map.tileheight)
    tileset_grid.draw_grid = true
    tileset_grid.insert_cell_layer(-1)

    # Add cropped pixbufs as the images for the image grid’s
    # cells until we run out of valid positions on the tileset.
    layer = tileset_grid.active_layer
    0.upto(Float::INFINITY) do |id|
      pos = tileset.tile_position(id)
      break unless pos

      # FIXME: When tmx-ruby provides a possibility to
      # calculate the logical tile position via a method
      # on Tileset, use that instead of doing the calculation
      # ourself.
      tx, ty = id % tileset.dimension[0], id / tileset.dimension[0]

      layer[tx, ty] = [Gdk::Pixbuf.new(tileset_pixbuf, pos[0], pos[1], tileset.tilewidth, tileset.tileheight),
                       {:gid => start_id + id}]
    end

    # If we receive a valid click on any of this
    # image grid’s tiles, set the mask to it so
    # we can retrieve this tile later easily in
    # #selected_tileset_tile (i.e. when we want to
    # draw it onto the map).
    # (This grid has only CellLayers, hence we need to typecheck)
    tileset_grid.signal_connect(:cell_button_release) do |_, hsh|
      if hsh[:pos]
        tileset_grid.clear_mask
        tileset_grid.add_to_mask(hsh[:pos])

        pos = hsh[:pos]
        signal_emit :selection_changed,
                    :page    => page,
                    :tileset => tileset,
                    :pos     => pos,
                    :info    => tileset_grid.get_cell(pos.cell_x, pos.cell_y, pos.cell_z)
      end
    end

    # Finally add the image grid to the tabbook so
    # it is available to the user.
    @pagenum2tileset.push(tileset)
    append_page(tileset_grid, Gtk::Label.new(File.basename(tileset.source.to_s)))
    tileset_grid.redraw!
  end

end
