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

  # Usual number of pixels between widgets
  THE_SPACE = 4

  # The application’s main window.
  attr_reader :mainwindow
  # The parsed contents of the configuration file. A hash
  # of form:
  #   {:key => value}
  attr_reader :config

  # Create the one and only instance of this class. Pass the
  # commandline options you want it to (destructively) parse.
  # Raises a RuntimeError if you call this more than once.
  def initialize(argv)
    raise("GUI already running!") if $app
    @argv        = argv
    @mainwindow  = nil
    @project     = nil
    $app         = self

    parse_argv
    parse_config
    set_locale
  end

  # Shortcut for dereferencing the THE_SPACE constant.
  # Returns the usual number of pixels between widgets;
  # this is read-only.
  def space
    THE_SPACE
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
  def main_loop
    Gtk.init
    GLib.application_name = t.general.application_name
    @mainwindow = OpenRubyRMK::GTKFrontend::MainWindow.new
    @mainwindow.show_all

    # GTK settings adjustments
    Gtk::Settings.default.tap do |settings|
      settings.gtk_button_images = true
    end

    Gtk.main
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

  private

  # Parse the commandline arguments.
  def parse_argv
    return if @argv.empty?

    # Accept the project directory as a path as well as
    # the .rmk file.
    path = Pathname.new(@argv.first)
    path = path.dirname.expand_path.parent if path.extname == ".rmk"

    @project = OpenRubyRMK::Backend::Project.load_dir(path)
  rescue OpenRubyRMK::Backend::Errors::InvalidPath => e
    $stderr.puts(e.message)
    @project = nil
  end

  # Parse GTKFrontend::base_config.
  def parse_config
    # Turn the string keys to symbols
    @config = Hash[OpenRubyRMK::GTKFrontend.bare_config.to_a.map{|k, v| [k.to_sym, v]}]
  end

  # Set the application’s locale.
  def set_locale
    if @config[:locale]
      R18n.from_env(OpenRubyRMK::GTKFrontend::LOCALE_DIR.to_s, @config[:locale])
    else
      R18n.from_env(OpenRubyRMK::GTKFrontend::LOCALE_DIR.to_s)
    end
  end

end
