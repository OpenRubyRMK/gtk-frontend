# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::ResourceDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize
    super("Resource manager",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_NONE])

    set_default_size 300, 400

    # $app.project.add_observer(self, :on_reload)

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @category_tree = OpenRubyRMK::GTKFrontend::Widgets::ResourceDirectoryTreeView.new
    # @resource_list = TreeView.new(ListStore.new(String))
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      hbox.pack_start(@category_tree, true)
      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response){destroy}
  end

  #def on_reload
  #  @resource_list.clear
  #end

end
