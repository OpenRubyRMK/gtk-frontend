# -*- coding: utf-8 -*-

# The GUI’s main application window.
class OpenRubyRMK::GTKFrontend::MainWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::MenuBuilder

  # Creates the application window.
  def initialize
    super
    set_default_size 400, 400

    create_menu
    create_widgets
    create_layout
    create_extra_windows
    setup_event_handlers

    self.project = nil
  end

  # As superclass method, but also calls
  # #show_all on all child windows.
  def show_all
    super
    @map_window.show_all
  end

  # Set or delete the current project. Enables/disables
  # menu entries accordingly.
  def project=(proj)
    if proj
      menu_items[:file_new].sensitive  = false
      menu_items[:file_open].sensitive = false
    else
      menu_items[:file_new].sensitive  = true
      menu_items[:file_open].sensitive = true
    end

    @project = proj
  end

  # Get the current project.
  def project
    @project
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
    @map_window = OpenRubyRMK::GTKFrontend::MapWindow.new(self)
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

    unless path.children.empty?
      $app.msgbox(self, t.dialogs.not_empty, :error, :close, :dir => path)
      return
    end

    self.project = Project.new(path)
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
      self.project = Project.load_dir(path)
    rescue OpenRubyRMK::Backend::Errors::NonexistantDirectory => e
      $app.msgbox(self, t.dialogs.dir_not_found, :error, :close, :dir => e.path)
      self.project = nil # Ensure we have a clean state
    end
  end

  # File -> Quit
  def on_menu_file_quit(event)
    Gtk.main_quit
  end

  def on_menu_windows_map_tree(event)
    if @map_window.visible?
      @map_window.hide
    else
      @map_window.show
    end
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
