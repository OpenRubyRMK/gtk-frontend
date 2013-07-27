# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::ToolWindows::LayerWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = "Layers"

    $app.state[:core].observe(:value_set) do |event, sender, info|
      reload_from_map(info[:value]) if info[:key] == :map
    end

    create_widgets
    create_layout
    setup_event_handlers

    reload_from_map($app.state[:core][:map])
  end

  private

  def create_widgets
    @add_button      = Button.new
    @del_button      = Button.new
    @settings_button = Button.new

    # The second column is a the layer name directly as this
    # allows us to use the easier and more performant text
    # renderer instead of a virtual one grabbing that property
    # from the layer instance. The pixbuf is the icon to use
    # for the layer.
    @layer_list = Gtk::TreeView.new(Gtk::ListStore.new(TiledTmx::Layer, String, Gdk::Pixbuf))

    @add_button.add(icon_image("ui/list-add.png", width: 16))
    @del_button.add(icon_image("ui/list-remove.png", width: 16))
    @settings_button.add(icon_image("ui/preferences-system.png", width: 16))
  end

  def create_layout
    VBox.new(false, $app.space).tap do |vbox|
      HBox.new(false, $app.space).tap do |hbox|
        hbox.pack_end(@settings_button, false)
        hbox.pack_end(@del_button, false)
        hbox.pack_end(@add_button, false)

        hbox.border_width = $app.space
        vbox.pack_start(hbox, false)
      end

      vbox.pack_start(@layer_list, true, true)
      add(vbox)
    end

    icon_renderer = Gtk::CellRendererPixbuf.new
    @name_renderer = Gtk::CellRendererText.new # We attach an event to this later, hence ivar
    icon_column   = Gtk::TreeViewColumn.new("", icon_renderer, pixbuf: 2) # model[2] The pixbuf to render
    name_column   = Gtk::TreeViewColumn.new("", @name_renderer, text: 1) # model[1] => layer name
    @layer_list.append_column(icon_column)
    @layer_list.append_column(name_column)

    @layer_list.rules_hint      = true
    @layer_list.headers_visible = false
    @layer_list.selection.mode  = Gtk::SELECTION_SINGLE
    @name_renderer.editable     = true
  end

  def setup_event_handlers
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
    @settings_button.signal_connect(:clicked, &method(:on_settings_button_clicked))
    @layer_list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
    @name_renderer.signal_connect(:edited, &method(:on_list_edited))
  end

  ########################################
  # Event handlers

  def on_add_button_clicked(event)
    return unless $app.state[:core][:map]

    td = OpenRubyRMK::GTKFrontend::Dialogs::ChoiceDialog.new(self,
                                                             t.dialogs.add_layer.title,
                                                             t.dialogs.add_layer.message,
                                                             [t.general.layer_types.tile, t.general.layer_types.object, t.general.layer_types.image])
    td.selection = 0
    td.run
    return if td.selection.nil?

    # These symbols are as undestood by ruby-tmx’ TiledTmx::Map#add_layer
    case td.selection
    when 0 then type = :tilelayer
    when 1 then type = :objectgroup
    when 2 then type = :imagelayer
    else
      raise("[BUG] Unknown layer type ##{td.selection}")
    end

    new_layer = $app.state[:core][:map].add_layer(type, :name => t.dialogs.add_layer.new_layer_name)
    prepend_layer(new_layer)
  end

  def on_del_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement the layer deletion button!")
  end

  def on_settings_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement the layer settings button!")
  end

  def on_list_cursor_changed(*)
    return unless @layer_list.cursor[0] # If no treepath is available, nothing is selected
    layer = @layer_list.model.get_iter(@layer_list.cursor[0])[0] # model[0] => Layer instance

    $app.state[:core][:z_index] = $app.state[:core][:map].layers.to_a.index{|l| l == layer}
  end

  def on_list_edited(cell, path, value)
    row         = @layer_list.model.get_iter(path)
    row[0].name = value # Layer instance
    row[1]      = value # Name shortcut for the list
  end

  ########################################
  # Helpers

  # Clears the list and rebuilds it from the layers found
  # in +map+.
  def reload_from_map(map)
    @layer_list.model.clear
    return unless map

    map.each_layer do |layer|
      prepend_layer(layer)
    end
  end

  def prepend_layer(layer)
    row = @layer_list.model.prepend
    row[0] = layer
    row[1] = layer.name

    case layer
    when TiledTmx::TileLayer   then row[2] = icon_pixbuf("ui/ball.png", width: 16)
    when TiledTmx::ObjectGroup then row[2] = icon_pixbuf("ui/exclamation.png", width: 16)
    when TiledTmx::ImageLayer  then row[2] = icon_pixbuf("ui/star.png", width: 16)
    else
      raise("Unsupported layer type: #{layer}")
    end
  end

end
