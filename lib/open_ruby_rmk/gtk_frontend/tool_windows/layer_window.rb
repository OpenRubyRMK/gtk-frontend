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
    # from the layer instance. The integer is the Z index of
    # the layer.
    @layer_list = Gtk::TreeView.new(Gtk::ListStore.new(TiledTmx::Layer, String))

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

    item_renderer = Gtk::CellRendererText.new
    item_column   = Gtk::TreeViewColumn.new("", item_renderer, text: 1) # model[1] => item text
    @layer_list.append_column(item_column)

    @layer_list.rules_hint      = true
    @layer_list.headers_visible = false
    @layer_list.selection.mode  = Gtk::SELECTION_SINGLE
  end

  def setup_event_handlers
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
    @settings_button.signal_connect(:clicked, &method(:on_settings_button_clicked))
    @layer_list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
  end

  ########################################
  # Event handlers

  def on_add_button_clicked(event)
    return unless $app.state[:core][:map]

    td = OpenRubyRMK::GTKFrontend::Dialogs::TextDialog.new(self, t.dialogs.add_layer.title, t.dialogs.add_layer.message)
    td.run
    return if td.text.nil? or td.text.empty?

    # We requre unique names for the layers so we can easily
    # determine the current Z index later on.
    if $app.state[:core][:map].tmx_map.layers.any?{|l| l.name == td.text}
      $app.msgbox(sprintf(t.dialogs.layer_name_taken, :name => td.text),
                  parent: self,
                  type: :warning)
      return
    end

    new_layer = $app.state[:core][:map].add_layer(:tile, :name => td.text)

    row = @layer_list.model.prepend
    row[0] = new_layer
    row[1] = new_layer.name
  end

  def on_del_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement the layer deletion button!")
  end

  def on_settings_button_clicked(event)
    raise(NotImplementedError, "Someone needs to implement the layer settings button!")
  end

  def on_list_cursor_changed(*)
    return unless @layer_list.cursor[0] # If no treepath is available, nothing is selected
    name = @layer_list.model.get_iter(@layer_list.cursor[0])[1] # model[1] => item text

    # As we require the layer name to be unique, we can
    # easily find the index of the newly selected layer
    # in the list of layers by name. That index also is
    # its Z position.
    $app.state[:core][:z_index] = $app.state[:core][:map].tmx_map.layers.to_a.index{|l| l.name == name}
  end

  ########################################
  # Helpers

  # Clears the list and rebuilds it from the layers found
  # in +map+.
  def reload_from_map(map)
    @layer_list.model.clear
    return unless map

    map.tmx_map.each_layer do |layer|
      row = @layer_list.model.prepend
      row[0] = layer
      row[1] = layer.name
    end
  end

end
