# -*- coding: utf-8 -*-

# The GUI’s main application window.
class OpenRubyRMK::GTKFrontend::MainWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::GtkHelper

  # Creates the application window.
  def initialize
    super
    set_default_size 400, 400

    create_menu
    create_widgets
    create_layout
    create_extra_windows
    setup_event_handlers

    # Ensure we get notified when the project we’re working
    # on gets changed.
    $app.add_observer(self, :app_changed)
  end

  # As superclass method, but also calls
  # #show_all on all child windows.
  def show_all
    super
    @map_tree_window.show_all
    @settings_window.show_all
  end

  # Event handler triggered by the observed App.
  # The observer is created in #initialize.
  #
  # It enables/disables menu entries as required.
  def app_changed(event, project) # :nodoc:
    return unless event == :project_changed

    # Menu entries
    if project
      menu_items[:file_new].sensitive  = false
      menu_items[:file_open].sensitive = false
    else
      menu_items[:file_new].sensitive  = true
      menu_items[:file_open].sensitive = true
    end
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

    menu @menubar, t.menus.windows.name do |windows|
      append_menu_item windows, t.menus.windows.entries.map_tree, :windows_map_tree
      append_menu_item windows, t.menus.windows.entries.map_tree, :windows_settings
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

  # Instanciates the helper windows.
  def create_extra_windows
    @map_tree_window = OpenRubyRMK::GTKFrontend::MapWindow.new(self)
    @settings_window = OpenRubyRMK::GTKFrontend::SettingsEditor.new(self)
  end

  # Connects the previously created widgets with event handlers.
  def setup_event_handlers
    # Generic window events
    signal_connect(:destroy, &method(:on_destroy))

    # Menus
    menu_items[:file_new].signal_connect(:activate, &method(:on_menu_file_new))
    menu_items[:file_open].signal_connect(:activate, &method(:on_menu_file_open))
    menu_items[:file_quit].signal_connect(:activate, &method(:on_menu_file_quit))
    menu_items[:windows_map_tree].signal_connect(:activate, &method(:on_menu_windows_map_tree))
    menu_items[:windows_settings].signal_connect(:activate, &method(:on_menu_windows_settings))
    menu_items[:help_about].signal_connect(:activate, &method(:on_menu_help_about))
  end

  ########################################
  # Event handlers

  # Application quit request.
  def on_destroy(event)
    Gtk.main_quit
  end

  # File -> New
  # I expect the creation of a new epic, one-in-a-million super fantistic game/project to
  # be a bit more exicting, than just type a short name and hit enter which just creates
  # a new directory. In my mind I see a little guy full of dreams and ideas who wants to
  # write his thoughts down in that very first step. Of course that things will change
  # a few times before the final release, so the dialog should be reusable as "change
  # project settings" - dialog. 
  # There might be an embedded-in-main-window-than-create-thousands-of-popupwindows-mode
  def on_menu_file_new(event)
    fd = FileChooserDialog.new(t.dialogs.new_project,
                               self,
                               FileChooser::ACTION_CREATE_FOLDER,
                               nil,
                               [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                               [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])

    if fd.run == Dialog::RESPONSE_ACCEPT
      path = Pathname.new(GLib.filename_to_utf8(fd.filename))
      fd.destroy
    else
      fd.destroy
      return
    end

    unless path.children.empty?
      $app.msgbox(self, t.dialogs.not_empty, :error, :close, :dir => path)
      return
    end

    $app.project = Project.new(path)
  end

  # File -> Open
  def on_menu_file_open(event)
    fd = FileChooserDialog.new(t.dialogs.new_project,
                               self,
                               FileChooser::ACTION_SELECT_FOLDER,
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
      $app.project = Project.load_dir(path)
    rescue OpenRubyRMK::Backend::Errors::NonexistantDirectory => e
      $app.msgbox(self, t.dialogs.dir_not_found, :error, :close, :dir => e.path)
      $app.project = nil # Ensure we have a clean state
    end
  end

  # File -> Quit
  def on_menu_file_quit(event)
    Gtk.main_quit
  end

  def self.toggleable_window(name)
    define_method "on_menu_windows_#{name.to_s}" do |event|
      hook = instance_variable_get("@#{name.to_s}_window")
      hook.send(hook.visible? ? :hide : :show)
    end
  end
  toggleable_window :map_tree
  toggleable_window :settings

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
