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
    @layer_list      = Gtk::TreeView.new(Gtk::ListStore.new(TiledTmx::Layer, String))

    @add_button.add(icon_image("ui/list-add.svg", width: 16))
    @del_button.add(icon_image("ui/list-remove.svg", width: 16))
    @settings_button.add(icon_image("ui/preferences-system.svg", width: 16))
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

    item_renderer = Gtk::CellRendererText.new
    item_column   = Gtk::TreeViewColumn.new("", item_renderer, text: 1) # model[1] => item text
    @layer_list.append_column(item_column)

    @layer_list.rules_hint      = true
    @layer_list.headers_visible = false
    @layer_list.selection.mode  = Gtk::SELECTION_SINGLE
  end

  def setup_event_handlers
  end

  # Clears the list and rebuilds it from the layers found
  # in +map+.
  def reload_from_map(map)
    @layer_list.model.clear
    return unless map

    map.tmx_map.each_layer do |layer|
      row = @layer_list.model.append
      row[0] = layer
      row[1] = layer.name
    end
  end

end
