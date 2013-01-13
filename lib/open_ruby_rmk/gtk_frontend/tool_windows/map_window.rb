# -*- coding: utf-8 -*-

# The window containing the map tree. Note that a MapWindow
# cannot be destroyed by the user; attempting to close it will
# effectively just hide the window, so it is easy to later
# re-display it.
class OpenRubyRMK::GTKFrontend::ToolWindows::MapWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  # Creates a new MapWindow. Pass in the parent window you want
  # to make this window a helper window of.
  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint     = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title         = t.windows.map_tree.title

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    @map_tree              = OpenRubyRMK::GTKFrontend::Widgets::MapTreeView.new
    @add_button            = Button.new
    @del_button            = Button.new
    @settings_button       = Button.new

    @add_button.add(icon_image("ui/list-add.svg", width: 16))
    @del_button.add(icon_image("ui/list-remove.svg", width: 16))
    @settings_button.add(icon_image("ui/preferences-system.svg", width: 16))
  end

  def create_layout
    t = VBox.new(false, $app.space).tap do |vbox|
      b = HBox.new(false, $app.space).tap do |row|
        row.pack_end(@settings_button, false)
        row.pack_end(@del_button, false)
        row.pack_end(@add_button, false)
      end

      b.border_width = $app.space
      vbox.pack_start(b, false)
      vbox.pack_start(@map_tree, true, true)
    end

    add(t)
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
    @settings_button.signal_connect(:clicked, &method(:on_settings_button_clicked))
    @map_tree.signal_connect(:cursor_changed, &method(:on_tree_cursor_changed))
  end

  ########################################
  # Event handlers

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  # + button
  def on_add_button_clicked(event)
    msd = OpenRubyRMK::GTKFrontend::Dialogs::MapSettingsDialog.new(nil, @map_tree.selected_map)
    msd.run
  end

  # - button
  def on_del_button_clicked(event)
    return unless @map_tree.selected_map

    map = @map_tree.selected_map
    result = $app.msgbox(t.dialogs.delete_map,
                         type: :question,
                         buttons: :yes_no,
                         params: {:name => map[:name], :id => map.id})
    return unless result == Dialog::RESPONSE_YES

    $app.project.remove_root_map(map) if map.root?
    map.unmount
  end

  def on_settings_button_clicked(event)
    return unless @map_tree.selected_map

    msd = OpenRubyRMK::GTKFrontend::Dialogs::MapSettingsDialog.new(@map_tree.selected_map)
    msd.run
  end

  def on_tree_cursor_changed(*)
    return unless @map_tree.selected_map

    $app.state[:core][:map] = @map_tree.selected_map
  end

end
