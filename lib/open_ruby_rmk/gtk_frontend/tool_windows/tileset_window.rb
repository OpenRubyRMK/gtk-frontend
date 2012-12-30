# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::ToolWindows::TilesetWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  # The grid showing the tileset’s tile images.
  attr_reader :tileset_grid

  # The selection mode as selected by the user.
  attr_reader :selection_mode

  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = t.windows.tileset.title

    @selection_mode = :rectangle

    parent.map_grid.add_observer(self, :map_grid_changed)

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    @tileset_tabs    = OpenRubyRMK::GTKFrontend::Widgets::TilesetBook.new
    @add_button      = Button.new
    @del_button      = Button.new
    @settings_button = Button.new

    @add_button.add(icon_image("ui/list-add.svg", width: 16))
    @del_button.add(icon_image("ui/list-remove.svg", width: 16))
    @settings_button.add(icon_image("ui/preferences-system.svg", width: 16))
  end

  def create_layout
    VBox.new.tap do |vbox|
      HBox.new(false, $app.space).tap do |hbox|
        hbox.pack_end(@settings_button, false)
        hbox.pack_end(@del_button, false)
        hbox.pack_end(@add_button, false)

        hbox.border_width = $app.space
        vbox.pack_start(hbox, false)
      end

      vbox.pack_start(@tileset_tabs, true, true)

      add(vbox)
    end
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
    @tileset_tabs.signal_connect(:selection_changed, &method(:on_selection_changed))
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
    @settings_button.signal_connect(:clicked, &method(:on_settings_button_clicked))
  end

  ########################################
  # Event handlers

  def map_grid_changed(event, sender, info)
    return unless event == :map_changed
    @tileset_tabs.map = info[:map]
  end
  public :map_grid_changed # For Observable

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  def on_selection_changed(_, hsh)
    $app.state[:core][:brush_gid] = hsh[:info].data[:gid]
    $app.state[:core][:brush_pixbuf] = hsh[:info].pixbuf
  end

  def on_add_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement adding tilesets to maps")
  end

  def on_del_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement removing tilesets from maps")
  end

  def on_settings_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement configuring map-specific tileset properties like terrain")
  end

end
