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
    main.append_page(game_design_outline_detailed, t.dialogs.settings.labels.detailed.title.to_label)
    main.append_page(game_design_outline_product_design, t.dialogs.settings.labels.product_design.title.to_label)
    vbox.add(main)
  end

  def general_settings_page
    options = VBox.new(false, 5)

    [:name, :base_path].each do |ele|
      sub = HBox.new(false, 0)
      sub.pack_start(t.dialogs.settings.labels.general.send(ele).to_label)
      sub.pack_start(Entry.new)
      options.pack_start(sub)
    end
    
    options.pack_start(t.dialogs.settings.labels.general.descr.to_label)
    options.pack_start(TextView.new)

    options    
  end
  
  # some tabs to write down your concept. Some might have done this before and don't need it but
  # i guess some of the questions might be worth of reading / rethinking
  # The outline ist based on http://www.sloperama.com/advice/specs.htm
  def game_design_outline_detailed
    options = VBox.new(false, 0)

    [:concept, :story, :objective, :gameplay, :intro, :additonal].each do |ele|
      expander = Expander.new(t.dialogs.settings.labels.detailed.send(ele), true)
      expander.expanded = false
      # I want to show the questions as shown above as default text, which will be deleted if the User clicks inside the Field, but I'm not good in gtk so
      # i can't find a suitable signal Oo. In FXRuby ALL elements got a clicked Signal .... Arghhh! So at the moment the user has to delete it himself.
      tb = TextBuffer.new
      tb.text = t.dialogs.settings.hints.detailed.send(ele)
      tv = TextView.new(tb)
      tv.height_request = 150
      #tv.signal_connect("clicked") {
        #tv.buffer = '' if tv.buffer.text == tb.text
      #}
      expander.add(tv)
      options.pack_start(expander)
    end
        
    options    
  end
  
  # Atm like the detailed view, but I guess it would be a nice feature if characters and world parts are a list
  # which pregenerates these elements in the related tables (charakter, map, script)
  def game_design_outline_product_design
    options = VBox.new(false, 0)
    
    [:characters, :world, :controls, :interface, :sound].each do |ele|
      expander = Expander.new(t.dialogs.settings.labels.product_design.send(ele), true)
      expander.expanded = false
      tb = TextBuffer.new
      tb.text = t.dialogs.settings.hints.product_design.send(ele)
      tv = TextView.new(tb)
      tv.height_request = 150
      expander.add(tv)
      options.pack_start(expander)      
    end
    
    options
  end
end
