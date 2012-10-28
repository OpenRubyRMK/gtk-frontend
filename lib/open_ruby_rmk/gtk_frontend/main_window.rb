# -*- coding: utf-8 -*-

# The GUI’s main application window.
class OpenRubyRMK::GTKFrontend::MainWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::MenuBuilder

  # Creates the application window.
  def initialize
    super
    set_default_size 400, 400

    create_menu
    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  # The menu bar.
  def create_menu
    @menubar = MenuBar.new

    menu @menubar, t.menus.file.name do |file|
      append_menu_item file, t.menus.file.entries.new, :file_new
      append_menu_item file, t.menus.file.entries.open, :file_open
      append_menu_separator file
      append_menu_item file, t.menus.file.entries.quit, :file_quit
    end

    menu @menubar, t.menus.edit.name do |edit|
    end

    menu @menubar, t.menus.help.name do |help|
      append_menu_item help, t.menus.help.entries.about, :help_about
    end

  end

  # Instanciates the widgets needed for the window.
  def create_widgets

  end

  # Lays out the previously created widgets.
  def create_layout
    VBox.new(false, 2).tap do |vbox|
      vbox.pack_start(@menubar, false, false, 0)
      add(vbox)
    end
  end

  # Connects the previously created widgets with event handlers.
  def setup_event_handlers
    # Generic window events
    signal_connect(:destroy, &method(:on_destroy))

    # Menus
    menu_items[:file_new].signal_connect(:activate, &method(:on_menu_file_new))
    menu_items[:file_open].signal_connect(:activate, &method(:on_menu_file_open))
    menu_items[:file_quit].signal_connect(:activate, &method(:on_menu_file_quit))
    menu_items[:help_about].signal_connect(:activate, &method(:on_menu_help_about))
  end

  ########################################
  # Event handlers

  # Application quit request.
  def on_destroy(event)
    Gtk.main_quit
  end

  # File -> New
  def on_menu_file_new(event)
  end

  # File -> Open
  def on_menu_file_open(event)
  end

  # File -> Quit
  def on_menu_file_quit(event)
    Gtk.main_quit
  end

  # Help -> About
  def on_menu_help_about(event)
    ad                    = AboutDialog.new
    ad.copyright          = "Copyright © 2012 The OpenRubyRMK Team"
    ad.website            = "http://devel.pegasus-alpha.eu/projects/openrubyrmk"
    ad.version            = OpenRubyRMK::GTKFrontend.version
    ad.license            = OpenRubyRMK::GTKFrontend.license
    ad.authors            = OpenRubyRMK::GTKFrontend.authors["programmers"].map{|name, email| "#{name} <#{email}>"}
    ad.artists            = OpenRubyRMK::GTKFrontend.authors["artists"].map{|name, email| "#{name} <#{email}>"}
    ad.documenters        = OpenRubyRMK::GTKFrontend.authors["documenters"].map{|name, email| "#{name} <#{email}>"}
    # ??? Why does GTK require this in another form...?
    ad.translator_credits = OpenRubyRMK::GTKFrontend.authors["translators"].map{|name, email| "#{name} <#{email}>"}.join("\n")

    ad.run do |response|
      ad.destroy
    end
  end

end
