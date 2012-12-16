# -*- coding: utf-8 -*-
# The window containing the map tree. Note that a SettingsEditor
# cannot be destroyed by the user; attempting to close it will
# effectively just hide the window, so it is easy to later
# re-display it.
class OpenRubyRMK::GTKFrontend::SettingsEditor < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::GtkHelper
  
  def initialize(parent)
    super()
    set_default_size 400, 300

    self.type_hint     = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title         = t.windows.settings.title

    create_widgets
  end
  
  def create_widgets
    main = Notebook.new
    main.append_page(general_settings_page, t.windows.settings.general.title.to_label)
    main.append_page(general_settings_page, t.windows.settings.general.title.to_label)
    main.append_page(general_settings_page, t.windows.settings.general.title.to_label)
    main.append_page(general_settings_page, t.windows.settings.general.title.to_label)
    self.add(main)
  end
  
  def general_settings_page
    options = VBox.new(false, 5)
    
    [:name, :descr, :base_path].each do |ele|
      sub = HBox.new(false, 0)
      sub.pack_start(t.windows.settings.general.send(ele).to_label)
      sub.pack_start(Entry.new)
      options.pack_start(sub)
    end
    
    options
  end
end