# Generic resource selection dialog. This class needs to be subclassed
# and the following methods need to be overridden:
#
# [initialize]
#   Ensure to call +super+ with +resource_dir+ set to the
#   subpath of the resource you want to query (e.g. "tilesets").
# [create_preview_widget]
#   Create the widget for the preview of the resource.
# [get_preview_widget]
#   Return the widget for the preview of the resource. It will
#   be added to a Gtk::HBox via #pack_start with the second
#   parameter set to true.
# [handle_cursor_changed]
#   User selected another path from thre tree view. This method gets
#   passed the selected path as a Pathname instance.
# [setup_signal_handlers]
#   Not required to override, but may be useful. Call +super+ (without
#   arguments) to ensure the main signal handlers also get set up.
#
# Additionally, this class mixes in the Validatable module and
# the OK button signal handler queries the validations. You can therefore
# set up your +validate+ blocks as expected.
class OpenRubyRMK::GTKFrontend::Dialogs::ResourceSelectionDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Validatable

  # The path the user selected, or +nil+ if none was selected
  # or the dialog was aborted.
  # Set after the click on the OK button.
  attr_reader :path

  # Create a new generic resource selection dialog.
  # == Parameters
  # [title]
  #   Title for the dialog.
  # [resource_dir]
  #   Resource *subdirectory* relative to the main resources path
  #   to allow selection from.
  # [parent]
  #   Parent window to be modal to. You can set this to $app.mainwindow.
  # == Return value
  # The newly created instance.
  def initialize(title, resource_dir, parent)
    super(title,
          parent,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    @path = nil
    @resource_dir = resource_dir
    set_default_size 500, 300

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Run the dialog showing all its child widgets.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @directory_tree = OpenRubyRMK::GTKFrontend::Widgets::DirectoryTreeView.new($app.project.paths.data_dir + @resource_dir, true)
    create_preview_widget
  end

  def create_layout
    HBox.new.tap do |hbox|
      hbox.pack_start(@directory_tree, false)
      hbox.pack_start(get_preview_widget, true)

      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @directory_tree.signal_connect(:cursor_changed, &method(:on_cursor_changed))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      $app.warnbox(validation_summary) and return unless valid?
      @path = @directory_tree.selected_path
    end

    destroy
  end

  def on_cursor_changed(*)
    return unless @directory_tree.selected_path
    return unless @directory_tree.selected_path.file?

    handle_cursor_changed(@directory_tree.selected_path)
  end

  def create_preview_widget
    # Must be overridden
  end

  def get_preview_widget
    # Must be overridden
  end

  def handle_cursor_changed
    # Must be overridden
  end

end
