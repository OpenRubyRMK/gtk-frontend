# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::CategoriesDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  def initialize
    super(t.dialogs.categories.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_ACCEPT])

    set_default_size 400, 300

    create_widgets
    create_layout
    setup_event_handlers

    #$app.project.categories.each do |cat|
    #  append_category(cat)
    #end
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @notebook   = Notebook.new
    @add_button = Button.new
    @del_button = Button.new

    @add_button.add(icon_image("ui/list-add.svg", width: 16))
    @del_button.add(icon_image("ui/list-remove.svg", width: 16))
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      hbox.pack_end(@del_button, false)
      hbox.pack_end(@add_button, false)

      hbox.border_width = $app.space
      vbox.pack_start(hbox, false)
    end

    vbox.pack_start(@notebook)
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    destroy
  end

  def on_add_button_clicked(*)
    cd = Dialogs::CategorySettingsDialog.new(self)
    cd.run
  end

  def on_del_button_clicked(*)
    raise(NotImplementedError, "Someone needs to implement deletion of categories")
  end

  ########################################
  # Helpers

  def append_category(cat)
    raise(NotImplementedError, "Someone must implemented appending categories")
  end

end
