# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::ResourceDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize
    super(t.dialogs.resources.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_NONE])

    set_default_size 300, 400

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
    @resource_list = OpenRubyRMK::GTKFrontend::Widgets::ListView.new
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      hbox.pack_start(@category_tree, true)
      hbox.pack_start(@resource_list, true)
      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response){destroy}
    @category_tree.signal_connect(:cursor_changed, &method(:on_category_tree_cursor_changed))
  end

  def on_category_tree_cursor_changed(*)
    @resource_list.model.clear

    @category_tree.selected_path.children.sort.each do |path|
      next unless path.file?
      next if path.extname == ".yml" # Ignore the info files, we load them separately on user request

      @resource_list.append(path.basename)
    end
  end

end
