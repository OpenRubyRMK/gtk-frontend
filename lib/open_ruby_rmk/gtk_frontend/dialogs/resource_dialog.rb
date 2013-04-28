# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::ResourceDialog < Gtk::Dialog
  include Gtk
  include OpenRubyRMK::GTKFrontend::Widgets
  include OpenRubyRMK::GTKFrontend::Helpers::Icons
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
    @resource_list  = ListView.new(true)
    @license_button = ImageLinkButton.new

    @import_button       = Button.new(t.general.actions.import)
    @export_button       = Button.new(t.general.actions.export)
    @preview_button      = Button.new
    @new_category_button = Button.new(t.dialogs.resources.labels.new_category)
    @delete_button       = Button.new(t.general.actions.delete)
    @details_label       = Label.new
    @details_button      = Button.new(t.dialogs.resources.labels.more)

    set_preview_button_image :start
    disable_buttons
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

        Alignment.new(0.5, 0.5, 0, 0).tap do |ali|
          ali.add(@preview_button)

          vbox2.pack_start(ali, true)
        end

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
      vbox2.pack_start(@new_category_button)
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
    @resource_list.edit_cell(&method(:on_resource_list_edit_cell))
    @preview_button.signal_connect(:clicked, &method(:on_preview_button_clicked))
    @import_button.signal_connect(:clicked, &method(:on_import_button_clicked))
    @export_button.signal_connect(:clicked, &method(:on_export_button_clicked))
    @details_button.signal_connect(:clicked, &method(:on_details_button_clicked))
  end

  ########################################
  # Event handlers

  def on_category_tree_cursor_changed(*)
    @resource_list.clear
    disable_buttons
    return unless @category_tree.selected_path

    reload_resource_list
  end

  def on_resource_list_cursor_changed(*)
    return unless @resource_list.selected_item
    enable_buttons

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

  def on_resource_list_edit_cell(cell, path, new_text)
    iter = @resource_list.model.get_iter(path) || return

    unless new_text.empty?
      res = OpenRubyRMK::Backend::Resource.new(@category_tree.selected_path + iter[0])

      res.path.rename(res.path.dirname + new_text)
      res.info_file.rename(res.info_file.dirname + "#{new_text}.yml")
      iter[0] = new_text
    end
  end

  def on_preview_button_clicked(*)
    return unless @category_tree.selected_path
    return unless @resource_list.selected_item

    if @preview_button_type == :start
      set_preview_button_image :stop

      res = OpenRubyRMK::Backend::Resource.new(@category_tree.selected_path + @resource_list.selected_item)
      rd = OpenRubyRMK::GTKFrontend::Dialogs::ResourcePreviewDialog.new(self, res)
      rd.run

      set_preview_button_image :start
    else # :stop
      # TODO
    end
  end

  def on_import_button_clicked(*)
    fd = FileChooserDialog.new(t.general.actions.import,
                           self,
                           FileChooser::ACTION_OPEN,
                           nil,
                           [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                           [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])

    if fd.run == Dialog::RESPONSE_ACCEPT
      path = Pathname.new(GLib.filename_to_utf8(fd.filename))
      fd.destroy
    else
      fd.destroy
      return
    end

    begin
      # Add the new resource
      if @category_tree.selected_path
        $app.project.add_resource(path, @category_tree.selected_path.relative_path_from($app.project.paths.resources_dir))
        reload_resource_list
      else # Just in case...
        $app.project.add_resource(path, ".") # Copies to the resources/ directory itself
        reload_resource_list($app.project.paths.resources_dir)
      end
    rescue OpenRubyRMK::Backend::Errors::NonexistantFile => e
      $app.msgbox("File not found: #{e.path}", type: :error, buttons: close)
    end
  end

  def on_export_button_clicked(*)
    return unless @category_tree.selected_path
    return unless @resource_list.selected_item
    resource = @category_tree.selected_path + @resource_list.selected_item

    fd = FileChooserDialog.new(t.general.actions.export,
                               self,
                               FileChooser::ACTION_SAVE,
                               nil,
                               [Stock::CANCEL, Dialog::RESPONSE_CANCEL],
                               [Stock::SAVE, Dialog::RESPONSE_ACCEPT])
    fd.current_name = resource.basename.to_s # Save name suggestion

    if fd.run == Dialog::RESPONSE_ACCEPT
      path = Pathname.new(GLib.filename_to_utf8(fd.filename))
      fd.destroy
    else
      fd.destroy
      return
    end

    FileUtils.mkdir_p(path.parent) unless path.parent.exist?
    FileUtils.cp(resource, path)
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

  ########################################
  # Helper methods

  # Clears the resource list widget and adds entries for all
  # resources found in +path+.
  def reload_resource_list(path = @category_tree.selected_path)
    @resource_list.clear

    path.children.sort.each do |childpath|
      next unless childpath.file?
      next if childpath.extname == ".yml" # Ignore the info files, we load them separately on user request

      @resource_list.append(childpath.basename)
    end
  end

  # Enable/Disable all buttons.
  def enable_buttons(enable = true)
    [@license_button, @preview_button, @import_button, @export_button, @new_category_button, @delete_button, @details_button].each do |button|
      button.sensitive = enable
    end
  end

  # Disable all buttons.
  def disable_buttons
    enable_buttons(false)
  end

  # Change the icon on the preview button to either :start or :stop.
  def set_preview_button_image(type)
    # If there’s any image already in there, remove it so
    # we can add a new one afterwards.
    @preview_button.remove(@preview_button.children.first) unless @preview_button.children.count.zero?

    if type == :stop
      @preview_button.add(icon_image("ui/media-playback-stop.png", width: 32))
    elsif type == :start
      @preview_button.add(icon_image("ui/media-playback-start.png", width: 32))
    end

    # Remember the type so we can act differently depending on
    # the shown icon.
    @preview_button_type = type

    # Don’t forget to show our new widget inside the button!
    @preview_button.show_all
  end

end
