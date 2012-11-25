# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::ResourceDialog < Gtk::Dialog
  include Gtk
  include OpenRubyRMK::GTKFrontend::Widgets
  include R18n::Helpers

  def initialize
    super(t.dialogs.resources.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_NONE])

    set_default_size 500, 500

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
    @category_frame = Frame.new(t.dialogs.resources.labels.categories)
    @resource_frame = Frame.new(t.dialogs.resources.labels.resources)
    @action_frame   = Frame.new(t.dialogs.resources.labels.actions)
    @details_frame  = Frame.new(t.dialogs.resources.labels.details)

    @category_tree  = ResourceDirectoryTreeView.new
    @resource_list  = ListView.new
    @license_button = ImageLinkButton.new

    @import_button       = Button.new(t.general.actions.import)
    @export_button       = Button.new(t.general.actions.export)
    @preview_button      = Button.new(t.dialogs.resources.labels.preview)
    @new_category_button = Button.new(t.dialogs.resources.labels.new_category)
    @rename_button       = Button.new(t.general.actions.rename)
    @delete_button       = Button.new(t.general.actions.delete)
    @details_label       = Label.new
    @details_button      = Button.new(t.dialogs.resources.labels.more)
  end

  def create_layout
    vbox.spacing = $app.space

    # Toplevel layout
    HBox.new.tap do |hbox|
      hbox.spacing = $app.space

      hbox.pack_start(@category_frame, true)
      hbox.pack_start(@resource_frame, true)

      VBox.new.tap do |vbox2|
        vbox2.spacing = $app.space

        vbox2.pack_start(@details_frame, false)
        vbox2.pack_end(@action_frame, false)

        hbox.pack_start(vbox2, false)
      end

      vbox.pack_start(hbox, true)
    end

    # Contents of the category and resource frames
    @category_frame.add(@category_tree)
    @resource_frame.add(@resource_list)

    # Contents of the action frame
    VBox.new.tap do |vbox2|
      vbox2.spacing = $app.space
      vbox2.pack_start(@import_button)
      vbox2.pack_start(@export_button)
      vbox2.pack_start(@preview_button)
      vbox2.pack_start(@new_category_button)
      vbox2.pack_start(@rename_button)
      vbox2.pack_start(@delete_button)

      @action_frame.add(vbox2)
    end

    # Contents of the details frame
    VBox.new.tap do |vbox2|
      vbox2.spacing = $app.space

      HBox.new.tap do |hbox|
        Alignment.new(0.5, 0.5, 0, 0).tap do |ali|
          ali.add(@license_button)
          hbox.pack_start(ali, true)
        end
        vbox2.pack_start(hbox, false)
      end

      vbox2.pack_start(@details_label)
      vbox2.pack_start(@details_button)

      @details_frame.add(vbox2)
    end
  end

  def setup_event_handlers
    signal_connect(:response){destroy}
    @category_tree.signal_connect(:cursor_changed, &method(:on_category_tree_cursor_changed))
    @resource_list.signal_connect(:cursor_changed, &method(:on_resource_list_cursor_changed))
    @details_button.signal_connect(:clicked, &method(:on_details_button_clicked))
  end

  def on_category_tree_cursor_changed(*)
    @resource_list.model.clear
    return unless @category_tree.selected_path

    @category_tree.selected_path.children.sort.each do |path|
      next unless path.file?
      next if path.extname == ".yml" # Ignore the info files, we load them separately on user request

      @resource_list.append(path.basename)
    end
  end

  def on_resource_list_cursor_changed(*)
    return unless @resource_list.selected_item

    # Retrieve the licensing information of this resource
    res = OpenRubyRMK::Backend::Resource.new(@category_tree.selected_path + @resource_list.selected_item)
    hsh = OpenRubyRMK::GTKFrontend::Licenser.decompose_license(res.copyright.license)

    # Change the license image
    @license_button.image = Gdk::Pixbuf.new(hsh[:icon].to_s, 100, -1)
    if hsh[:url]
      @license_button.uri = hsh[:url]
      @license_button.sensitive = true
    else
      @license_button.uri = ""
      @license_button.sensitive = false
    end

    # Change the details text
    @details_label.markup =<<-DETAILS
<b>#{t.dialogs.resources.labels.license}</b>:
  #{res.copyright.license}
<b>#{t.dialogs.resources.labels.copyright_year}</b>:
  #{res.copyright.year}
<b>#{t.dialogs.resources.labels.copyright_holder}</b>:
  #{res.copyright.author}
    DETAILS
  end

  def on_details_button_clicked(*)
    return unless @resource_list.selected_item

    res = OpenRubyRMK::Backend::Resource.new(@category_tree.selected_path + @resource_list.selected_item)
    msg = "Copyright © #{res.copyright.year} #{res.copyright.author}"
    msg << "\n\n" << res.copyright.extra_info

    md = MessageDialog.new(self,
                           Dialog::DESTROY_WITH_PARENT,
                           MessageDialog::INFO,
                           MessageDialog::BUTTONS_CLOSE,
                           msg)
    md.run
    md.destroy
  end

end
