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
class OpenRubyRMK::GTKFrontend::App
  include R18n::Helpers

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
    $app         = self

    parse_config
    set_locale
  end

  # Starts the main application loop, handing over the control
  # to the GTK library. Call this when you have set up everything
  # else and want to let the event handling begin.
  def main_loop
    Gtk.init
    GLib.application_name = t.general.application_name
    @mainwindow = OpenRubyRMK::GTKFrontend::MainWindow.new
    @mainwindow.show_all
    Gtk.main
  end

  # Displays a message box modal to the given window. The
  # dialog is automatically destoyed for you.
  # == Parameters
  # [parent]
  #   The parent to block while the dialog is shown. +nil+
  #   should also work (untested).
  # [msg]
  #   The message to display.
  # [type (:info)]
  #   The type of the message box. One of :error, :question,
  #   :info, :warning, :other.
  # [buttons (:ok)]
  #   The buttons to display. One of :cancel, :close, :ok,
  #   :none (don’t use this), :ok_cancel, :yes_no.
  # [hsh ({})]
  #   Sprintf parameters to inject into +msg+. Most useful
  #   in combination with translations.
  # == Return value
  #   The return value of MessageDialog#run.
  def msgbox(parent, msg, type = :info, buttons = :ok, hsh = {})
    md = Gtk::MessageDialog.new(parent,
                                Gtk::Dialog::DESTROY_WITH_PARENT,
                                Gtk::MessageDialog.const_get(type.upcase),
                                Gtk::MessageDialog.const_get(:"BUTTONS_#{buttons.upcase}"),
                                sprintf(msg, hsh))
    result = md.run
    md.destroy
    result
  end

  private

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
