# -*- coding: utf-8 -*-

# The window containing the map tree. Note that a MapWindow
# cannot be destroyed by the user; attempting to close it will
# effectively just hide the window, so it is easy to later
# re-display it.
class OpenRubyRMK::GTKFrontend::MapWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend


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
    @map_tree              = OpenRubyRMK::GTKFrontend::MapTreeView.new
    @add_button            = Button.new
    @del_button            = Button.new
    @settings_button       = Button.new

    @add_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("plus.png").to_s))
    @del_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("minus.png").to_s))
    @settings_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("gear.png").to_s))

    # On startup, when no projects are loaded, these
    # buttons are disabled.
    @add_button.sensitive      = false
    @del_button.sensitive      = false
    @settings_button.sensitive = false

    # Enable/Disable buttons depending on the project state
    $app.observe(:project_changed) do |event, emitter, info|
      [@add_button, @del_button, @settings_button].each do |button|
        button.sensitive = !!info[:project]
      end
    end
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
  end

  ########################################
  # Event handlers

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  # + button
  def on_add_button_clicked(event)
    msd = OpenRubyRMK::GTKFrontend::MapSettingsDialog.new(nil, @map_tree.selected_map)
    msd.run
  end

  # - button
  def on_del_button_clicked(event)
  end

  def on_settings_button_clicked(event)
    return unless @map_tree.selected_map

    msd = OpenRubyRMK::GTKFrontend::MapSettingsDialog.new(@map_tree.selected_map)
    msd.run
  end

end
