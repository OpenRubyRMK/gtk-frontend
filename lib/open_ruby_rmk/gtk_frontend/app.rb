# -*- coding: utf-8 -*-

# This variable holds the global application instance. There will
# only ever be one instance of the App class, which rejects to
# instanciate if this is already set. A global should be safe here.
$app = nil

# This class represents the entire GUI application with all its
# windows, configuration, etc. It is only instanciated once
# (further tries will cause an error) and is after the
# instanciation always available in the global variable
# $application.
#
# The instance of this class includes the Eventable module,
# which allows you to listen for certain events; which events
# are emitted is documented in the respective methods issuing
# it. See the Eventable module’s documentation for how to
# add a listener (it’s part of the backend documentation).
class OpenRubyRMK::GTKFrontend::App
  include R18n::Helpers
  include OpenRubyRMK::Backend::Eventable
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  # Usual number of pixels between widgets
  THE_SPACE = 4

  # The application’s main window.
  attr_reader :mainwindow
  # The parsed contents of the configuration file. A hash
  # of form:
  #   {:key => value}
  attr_reader :config

  # The parsed contents of the cache file, as a hash. This
  # hash gets written out to disk as-is in the user’s cache
  # directory and is not meant to be edited by the user. You
  # can use this to store non-critical data that speeds up
  # some operations or provides other conveniences, but do not
  # rely on it to be available — the cache directory may be
  # deleted by the user, which shouldn’t have any serious
  # impact on the application.
  attr_reader :cache

  # The Gtk::IconFactory we use to provide GTK with our own
  # menu icons.
  attr_reader :icon_factory

  # A recursive hash-alike that can be used for storing anything
  # needed globally in the entire application.
  # 'Recursive' in this context means accessing unset keys
  # will automatically create a new object of this type for you (which
  # in turn has this functionality itself).
  # You can +observe+ this object, listening for the +value_set+ event,
  # to get informed whenever something in here changes.
  attr_reader :state

  # Create the one and only instance of this class. Pass the
  # commandline options you want it to (destructively) parse.
  # Raises a RuntimeError if you call this more than once.
  def initialize(argv)
    raise("GUI already running!") if $app
    @argv        = argv
    @mainwindow  = nil
    @project     = nil
    $app         = self
    @state       = OpenRubyRMK::GTKFrontend::EventedStorage.new
    @is_ready    = false

    parse_argv
    parse_config
    load_cache
    set_locale
    register_stock_icons
    init_state
  end

  # Shortcut for dereferencing the THE_SPACE constant.
  # Returns the usual number of pixels between widgets;
  # this is read-only.
  def space
    THE_SPACE
  end

  # Returns true if all setup (including main loop
  # initialisation) has been done (i.e. whether
  # we already handed control over to GTK completely).
  # Otherwise, returns false.
  def is_ready?
    @is_ready
  end

  # Set the project we’re currently working on. Be *very*
  # careful when setting this, as it most likely affects
  # your whole UI.
  #
  # This method notifies event listeners with the
  # :project_changed event.
  def project=(proj)
    changed
    @project = proj
    notify_observers(:project_changed, :project => @project)
  end

  # The project we’re currently working on.
  def project
    @project
  end

  # Starts the main application loop, handing over the control
  # to the GTK library. Call this when you have set up everything
  # else and want to let the event handling begin.
  #
  # When the main loop has finished, automatically calls #finalize
  # (a private method).
  def main_loop
    Gtk.init
    GLib.application_name = t.general.application_name
    @mainwindow = OpenRubyRMK::GTKFrontend::MainWindow.new
    @mainwindow.show_all

    # GTK settings adjustments
    Gtk::Settings.default.tap do |settings|
      settings.gtk_button_images = true
    end

    @is_ready = true
    Gtk.main

    finalize
  end

  # Displays a message box modal to the given window. The
  # dialog is automatically destoyed for you.
  # == Parameters
  # [msg]
  #   The message to display.
  # [opts ({})]
  #   An options hash with the following parameters:
  #   [parent (application main window)]
  #     The parent to block while the dialog is shown. +nil+
  #     should also work (untested).
  #   [type (:info)]
  #     The type of the message box. One of :error, :question,
  #     :info, :warning, :other.
  #   [buttons (:ok)]
  #     The buttons to display. One of :cancel, :close, :ok,
  #     :none (don’t use this), :ok_cancel, :yes_no.
  #   [params ({})]
  #     Sprintf parameters to inject into +msg+. Most useful
  #     in combination with translations.
  # == Return value
  #   The return value of MessageDialog#run.
  def msgbox(msg, opts = {})
    opts[:type]    ||= :info
    opts[:buttons] ||= :ok
    opts[:parent]  ||= @mainwindow
    opts[:params]  ||= {}

    md = Gtk::MessageDialog.new(opts[:parent],
                                Gtk::Dialog::DESTROY_WITH_PARENT | Gtk::Dialog::MODAL,
                                Gtk::MessageDialog.const_get(opts[:type].upcase),
                                Gtk::MessageDialog.const_get(:"BUTTONS_#{opts[:buttons].upcase}"),
                                sprintf(msg, opts[:params]))
    result = md.run
    md.destroy
    result
  end

  # Convenience method equivalent to:
  #   msgbox(msg, type: :warning)
  def warnbox(msg)
    msgbox(msg, type: :warning)
  end

  private

  # Run once the main loop has exited. Clean up code belongs
  # here.
  def finalize
    dump_cache
  end

  # Parse the commandline arguments.
  def parse_argv
    return if @argv.empty?

    # The one and only argument may be a path to a .rmk file
    path = Pathname.new(@argv.first)

    @project = OpenRubyRMK::Backend::Project.load_project_file(path)
  rescue OpenRubyRMK::Backend::Errors::InvalidPath => e
    $stderr.puts(e.message)
    @project = nil
  end

  # Parse GTKFrontend::base_config.
  def parse_config
    # Turn the string keys to symbols
    @config = Hash[OpenRubyRMK::GTKFrontend.bare_config.to_a.map{|k, v| [k.to_sym, v]}]
  end

  # Read the cache file (i.e. the file for storing non-critical,
  # non-user-editable information).
  def load_cache
    # Create the cache directory if it doesn’t exist
    cache_file = OpenRubyRMK::GTKFrontend::USER_CACHE_DIR + "cache.bin"
    cache_file.parent.mkpath unless cache_file.parent.directory?

    # If there’s no cache file, just use an empty cache.
    @cache = cache_file.file? ? cache_file.open("rb"){|f| Marshal.load(f)} : {}
  end

  # Write the cache file from the current content of @cache.
  # The cache file is not meant to be user-editable nor to
  # contain permanent, critical information.
  def dump_cache
    # The cache directory is guaranteed to exist by #read_cache.
    cache_file = OpenRubyRMK::GTKFrontend::USER_CACHE_DIR + "cache.bin"
    cache_file.open("wb"){|f| Marshal.dump(@cache, f)}
  end

  # Set the application’s locale.
  def set_locale
    if @config[:locale]
      R18n.from_env(OpenRubyRMK::GTKFrontend::LOCALE_DIR.to_s, @config[:locale])
    else
      R18n.from_env(OpenRubyRMK::GTKFrontend::LOCALE_DIR.to_s)
    end
  end

  # Tells GTK about our custom menu icons.
  def register_stock_icons
    # Create a new icon factory and make GTK search it for
    # menu items.
    @icon_factory = Gtk::IconFactory.new
    @icon_factory.add_default

    # Now add all our custom menu icons.
    # NOTE: If you want to add to this, please always use "orr_" as a prefix
    # for your names. This allows to easily see in-code whether an icon has
    # been added by the ORR code or is a GTK stock builtin.
    register_stock_icon(:orr_freehand_selection, "ui/selection-freehand.png", t.tools.selection.freehand)
    register_stock_icon(:orr_magic_selection, "ui/selection-magic.png", t.tools.selection.magic)
    register_stock_icon(:orr_rectangle_selection, "ui/selection-rectangle.png", t.tools.selection.rectangle)
    register_stock_icon(:orr_character_editor, "ui/editor-character.png", t.tools.editor.character)
    register_stock_icon(:orr_free_editor,"ui/editor-free.png", t.tools.editor.free)
  end

  # Adds a single custom menu item to GTK. +path+ is
  # a path relative to data/icons, +label+ is the label
  # to display next to the icon if requested.
  # +name+ is the key used to look up icon and label (a
  # Symbol).
  def register_stock_icon(name, path, label)
    Gtk::Stock.add(name, label)
    iconset = Gtk::IconSet.new(icon_pixbuf(path, width: 32, height: 32))
    @icon_factory.add(name.to_s, iconset) # For some unknown reason, this must be a string
  end

  # Initialise the global state to the default
  # values.
  def init_state
    @state[:core][:map]            = nil         # Active map
    @state[:core][:z_index]        = 0           # Current layer’s Z index
    @state[:core][:selection_mode] = :rectangle  # Selection tool in use
    @state[:core][:objects_mode]   = :character  # Object editor tool in use
    @state[:core][:brush_gid]      = nil
    @state[:core][:brush_pixbuf]   = nil
    @state[:core][:test_pid]       = nil         # Process Identifier of the running game test, if any
  end

end
