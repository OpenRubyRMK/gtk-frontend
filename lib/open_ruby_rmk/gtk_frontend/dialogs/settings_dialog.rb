# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Dialogs::SettingsDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::Helpers::GtkHelper

  def initialize
    super(t.dialogs.settings.title,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])
    set_default_size 400, 300

    create_widgets
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    main = Notebook.new
    main.append_page(general_settings_page, t.dialogs.settings.labels.general.title.to_label)
    main.append_page(general_settings_page, t.dialogs.settings.labels.general.title.to_label)
    main.append_page(general_settings_page, t.dialogs.settings.labels.general.title.to_label)
    main.append_page(general_settings_page, t.dialogs.settings.labels.general.title.to_label)
    vbox.add(main)
  end

  def general_settings_page
    options = VBox.new(false, 5)

    [:name, :descr, :base_path].each do |ele|
      sub = HBox.new(false, 0)
      sub.pack_start(t.dialogs.settings.labels.general.send(ele).to_label)
      sub.pack_start(Entry.new)
      options.pack_start(sub)
    end

    options
  end
end
