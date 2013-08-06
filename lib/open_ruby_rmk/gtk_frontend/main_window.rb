# -*- coding: utf-8 -*-

# The GUI’s main application window.
class OpenRubyRMK::GTKFrontend::MainWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend
  include OpenRubyRMK::GTKFrontend::Helpers::GtkHelper

  # Creates the application window.
  def initialize
    super
    set_default_size 640, 480

    create_menu
    create_toolbar
    create_widgets
    create_layout
    create_extra_windows
    setup_event_handlers

    # Enable/Disable menu entries at the beginning for the currently
    # loaded project (which is nil if no project path was passed via
    # commandline).
    update_menu_entries($app.project)

    # Refresh the menu entries when the selected project changes.
    $app.observe(:project_changed){|event, emitter, info| update_menu_entries(info[:project])}
    $app.state[:core].observe(:value_set){|even, sender, info| update_layer_tools if info[:key] == :z_index}
  end

  # As superclass method, but also calls
  # #show_all on all desired child windows.
  def show_all
    super
    @map_window.show_all
    @tileset_window.show_all
    @layer_window.show_all

    # Restore window positions if requested and possible
    if $app.config[:remember_window_positions]
      move(*$app.cache[:main_window_position])                    if $app.cache[:main_window_position]
      @map_window.move(*$app.cache[:map_window_position])         if $app.cache[:map_window_position]
      @tileset_window.move(*$app.cache[:tileset_window_position]) if $app.cache[:tileset_window_position]
      @layer_window.move(*$app.cache[:layer_window_position])     if $app.cache[:layer_window_position]

    # Otherwise try to position best suited for the current screen resolution
    else
      dw = screen.width - @map_window.default_width - @tileset_window.default_width - 100
      dh = screen.height
      resize(dw,dh)

      @map_window.move(0,0)
      @map_window.resize(@map_window.default_width, dh)

      move(@map_window.default_width+70,0)

      @tileset_window.move(@map_window.default_width+dw+100,0)
      @tileset_window.resize(@tileset_window.default_width, dh / 2 - 100)

      @layer_window.move(@map_window.default_width+dw+100,dh / 2)
      @layer_window.resize(@layer_window.default_width, dh / 2)
    end
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
      append_menu_item(file, t.menus.file.entries.open, :file_open)
      append_menu_item(file, t.menus.file.entries.recent_opened, :file_recent_opened).set_submenu(OpenRubyRMK::GTKFrontend::Widgets::RecentOpenMenu.new(file))
      append_menu_separator file
      append_menu_item file, t.menus.file.entries.save, :file_save
      append_menu_separator file
      append_menu_item file, t.menus.file.entries.test, :file_test
      append_menu_item file, t.menus.file.entries.package, :file_package
      append_menu_separator file
      append_menu_item file, t.menus.file.entries.quit, :file_quit
    end

    menu @menubar, t.menus.edit.name do |edit|
      append_menu_item edit, t.menus.edit.entries.resources, :edit_resources
      append_menu_item edit, t.menus.edit.entries.project_settings, :edit_project_settings
      append_menu_item edit, t.menus.edit.entries.categories, :edit_categories
      append_menu_item edit, t.menus.edit.entries.templates, :edit_templates
    end

    menu @menubar, t.menus.view.name do |view|
      append_menu_item view, t.menus.view.entries.grid, :view_grid
    end

    menu @menubar, t.menus.windows.name do |windows|
      append_menu_item windows, t.menus.windows.entries.map_tree, :windows_map_tree
      append_menu_item windows, t.menus.windows.entries.tileset, :windows_tileset
      append_menu_item windows, t.menus.windows.entries.layer, :windows_layer
      append_menu_separator windows
      append_menu_item windows, t.menus.windows.entries.console, :windows_console
    end

    menu @menubar, t.menus.help.name do |help|
      append_menu_item help, t.menus.help.entries.about, :help_about
    end
  end

  def create_toolbar
    @toolbar = Toolbar.new
    @tools = Hash.new{|hsh, k| hsh[k] = Hash.new(&hsh.default_proc)}

    @tools[:objects][:chartype]  = ToolItem.new.tap{|item| item.add(OpenRubyRMK::GTKFrontend::Widgets::TemplateCombobox.new)}
    @tools[:objects][:chartypel] = ToolItem.new.tap{|item| item.add(Label.new(t.tools.chartype.label))}
    @tools[:objects][:character] = RadioToolButton.new(nil, :orr_character_editor)
    @tools[:objects][:free]      = RadioToolButton.new(@tools[:objects][:character], :orr_free_editor)
    @tools[:objects][:edit]      = RadioToolButton.new(@tools[:objects][:character], :orr_edit_editor)

    @tools[:selection][:rect]  = RadioToolButton.new(nil, :orr_rectangle_selection)
    @tools[:selection][:magic] = RadioToolButton.new(@tools[:selection][:rect], :orr_magic_selection)
    @tools[:selection][:free]  = RadioToolButton.new(@tools[:selection][:rect], :orr_freehand_selection)

    @tools[:general][:save] = ToolButton.new(:orr_save)
    @tools[:general][:open] = ToolButton.new(:orr_open)
    @tools[:general][:new] = ToolButton.new(:orr_new)

    @tools[:objects].each_value do |tool|
      @toolbar.insert(0, tool)
      tool.sensitive = false # Start with all tools disabled
    end
    @toolbar.insert(0, SeparatorToolItem.new)

    @tools[:selection].each_value do |tool|
      @toolbar.insert(0, tool)
      tool.sensitive = false # Start with all tools disabled
    end
    @toolbar.insert(0, SeparatorToolItem.new)

    @tools[:general].each_value do |tool|
      @toolbar.insert(0, tool)
      tool.sensitive = false # Start with all tools disabled
    end

    @tools[:objects][:chartype].sensitive  = true
    @tools[:objects][:chartypel].sensitive = true

    @tools[:selection][:rect].active = true
    @tools[:objects][:edit].active   = true
  end

  # Instanciates the widgets needed for the window.
  def create_widgets
    @map_grid = OpenRubyRMK::GTKFrontend::Widgets::MapGrid.new(OpenRubyRMK::Backend::Map::DEFAULT_TILE_EDGE,
                                                               OpenRubyRMK::Backend::Map::DEFAULT_TILE_EDGE)
    @map_grid.draw_grid = $app.config[:grid]
    @map_grid.show_active_cell = $app.config[:show_active_cell]
    @map_grid.alpha_layers = $app.config[:alpha_layers] ? 0.5 : 1
  end

  # Lays out the previously created widgets.
  def create_layout
    VBox.new(false, 2).tap do |vbox|
      vbox.pack_start(@menubar, false)
      vbox.pack_start(@toolbar, false)

      HBox.new.tap do |hbox|
        hbox.pack_start(@map_grid)
        vbox.pack_start(hbox)
      end

      add(vbox)
    end
  end

  # Instanciates the helper windows.
  def create_extra_windows
    @map_window     = OpenRubyRMK::GTKFrontend::ToolWindows::MapWindow.new(self)
    @tileset_window = OpenRubyRMK::GTKFrontend::ToolWindows::TilesetWindow.new(self)
    @layer_window   = OpenRubyRMK::GTKFrontend::ToolWindows::LayerWindow.new(self)
    @console_window = OpenRubyRMK::GTKFrontend::ToolWindows::ConsoleWindow.new(self)
  end

  # Connects the previously created widgets with event handlers.
  def setup_event_handlers
    # Generic window events
    signal_connect(:destroy, &method(:on_destroy))

    # Menus
    menu_items[:file_new].signal_connect(:activate, &method(:on_menu_file_new))
    menu_items[:file_open].signal_connect(:activate, &method(:on_menu_file_open))
    menu_items[:file_recent_opened].submenu.signal_connect('item-activated', &method(:on_menu_file_recent_opened))
    menu_items[:file_save].signal_connect(:activate, &method(:on_menu_file_save))
    menu_items[:file_test].signal_connect(:activate, &method(:on_menu_file_test))
    menu_items[:file_package].signal_connect(:activate, &method(:on_menu_file_package))
    menu_items[:file_quit].signal_connect(:activate, &method(:on_menu_file_quit))
    menu_items[:edit_resources].signal_connect(:activate, &method(:on_menu_edit_resources))
    menu_items[:edit_project_settings].signal_connect(:activate, &method(:on_menu_edit_project_settings))
    menu_items[:edit_categories].signal_connect(:activate, &method(:on_menu_edit_categories))
    menu_items[:edit_templates].signal_connect(:activate, &method(:on_menu_edit_templates))
    menu_items[:view_grid].signal_connect(:activate, &method(:on_menu_view_grid))
    menu_items[:windows_map_tree].signal_connect(:activate, &method(:on_menu_windows_map_tree))
    menu_items[:windows_tileset].signal_connect(:activate, &method(:on_menu_windows_tileset))
    menu_items[:windows_layer].signal_connect(:activate, &method(:on_menu_windows_layer))
    menu_items[:windows_console].signal_connect(:activate, &method(:on_menu_windows_console))
    menu_items[:help_about].signal_connect(:activate, &method(:on_menu_help_about))

    # Toolbar
    @tools[:selection][:rect].signal_connect(:toggled, &method(:on_tool_selection_rect))
    @tools[:selection][:magic].signal_connect(:toggled, &method(:on_tool_selection_magic))
    @tools[:selection][:free].signal_connect(:toggled, &method(:on_tool_selection_free))
    @tools[:objects][:edit].signal_connect(:toggled, &method(:on_tool_objects_edit))
    @tools[:objects][:character].signal_connect(:toggled, &method(:on_tool_objects_character))
    @tools[:objects][:free].signal_connect(:toggled, &method(:on_tool_objects_free))
    @tools[:general][:new].signal_connect(:clicked, &method(:on_menu_file_new))
    @tools[:general][:open].signal_connect(:clicked, &method(:on_menu_file_open))
    @tools[:general][:save].signal_connect(:clicked, &method(:on_menu_file_save))
  end

  ########################################
  # Event handlers

  # Application quit request.
  def on_destroy(event)
    # Remember the positions (this is done always, regardless
    # of the config option. Instead, the config option
    # just determines whether we *load* this info on
    # startup).
    $app.cache[:main_window_position]    = position
    $app.cache[:map_window_position]     = @map_window.position
    $app.cache[:tileset_window_position] = @tileset_window.position
    $app.cache[:layer_window_position]   = @layer_window.position

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
                               FileChooser::Action::SELECT_FOLDER,
                               nil,
                               [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                               [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])

    if fd.run == Dialog::RESPONSE_ACCEPT
      path = Pathname.new(GLib.filename_to_utf8(fd.filename)).expand_path
      fd.destroy
    else
      fd.destroy
      return
    end

    unless path.children.empty?
      $app.msgbox(t.dialogs.not_empty,
                  type: :error,
                  buttons: :close,
                  params: {:dir => path})
      return
    end

    $app.project = Project.new(path)
  end

  # File -> Open
  def on_menu_file_open(event)
    filter = FileFilter.new
    filter.name = "OpenRubyRMK project files (*.rmk;*.RMK)"
    filter.add_pattern("*.rmk")
    filter.add_pattern("*.RMK")

    fd = FileChooserDialog.new(t.dialogs.new_project,
                               self,
                               FileChooser::ACTION_OPEN,
                               nil,
                               [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                               [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    fd.add_filter(filter)

    if fd.run == Dialog::RESPONSE_ACCEPT
      path = Pathname.new(GLib.filename_to_utf8(fd.filename)).expand_path
      fd.destroy
    else
      fd.destroy
      return
    end

    begin
      $app.project = Project.load_project_file(path)
    rescue OpenRubyRMK::Backend::Errors::NonexistantFile => e
      $app.msgbox(t.dialogs.file_not_found, type: :error, buttons: :close, params: {:file => e.path})
      $app.project = nil # Ensure we have a clean state
    end
  end

  # File -> Open Recent
  # The rescue isn't really neccessary because I set the "existing files only" filter
  def on_menu_file_recent_opened(event)
    begin
      $app.project = Project.load_project_file(event.current_uri.gsub('file://',''))
    rescue OpenRubyRMK::Backend::Errors::NonexistantFile => e
      $app.msgbox(t.dialogs.file_not_found, type: :error, buttons: :close, params: {:file => e.path})
      $app.project = nil # Ensure we have a clean state
    end
  end

  # File -> Save
  def on_menu_file_save(event)
    $app.project.save
  end

  # File -> Test
  def on_menu_file_test(event)
    Bundler.with_clean_env do
      $app.state[:core][:test_pid] = spawn({"ORR_DEBUG" => "1"},
                                           "'#{ENV['BUNDLE_BIN_PATH']}' exec '#{$app.project.paths.start_file}'",
                                           chdir: $app.project.paths.root.to_s)

    end

    # FIXME: Add a modal dialog with a stop button so
    # the main UI is blocked, but the test can still be
    # aborted.
  end

  # File -> Package
  def on_menu_file_package(event)
    fd = FileChooserDialog.new(t.dialogs.package,
                               self,
                               FileChooser::Action::SELECT_FOLDER,
                               nil,
                               [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                               [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])

    begin
      if fd.run == Dialog::RESPONSE_ACCEPT
        path = Pathname.new(GLib.filename_to_utf8(fd.filename)).expand_path
      else
        return
      end
    ensure
      fd.destroy
    end

    unless path.children.empty?
      $app.msgbox(t.dialogs.not_empty,
                  type: :error,
                  buttons: :close,
                  params: {:dir => path})
      return
    end

    $app.project.package(path)
  end

  # File -> Quit
  def on_menu_file_quit(event)
    destroy # Fires the `destroy' event, which in turn triggers #on_destroy
  end

  # Edit -> Resources...
  def on_menu_edit_resources(event)
    rd = OpenRubyRMK::GTKFrontend::Dialogs::ResourceDialog.new
    rd.run
  end

  # Edit -> Templates...
  def on_menu_edit_templates(event)
    td = OpenRubyRMK::GTKFrontend::Dialogs::TemplatesDialog.new
    td.run
  end

  # Edit -> Project Settings...
  def on_menu_edit_project_settings(event)
    sd = OpenRubyRMK::GTKFrontend::Dialogs::SettingsDialog.new
    sd.run
  end

  # Edit -> Categories
  def on_menu_edit_categories(event)
    cd = OpenRubyRMK::GTKFrontend::Dialogs::CategoriesDialog.new
    cd.run
  end

  # View -> Grid
  def on_menu_view_grid(event)
    @map_grid.draw_grid = !@map_grid.draw_grid?
    @map_grid.redraw!
  end

  # Windows -> Map tree
  def on_menu_windows_map_tree(event)
    if @map_window.visible?
      @map_window.hide
    else
      @map_window.show
    end
  end

  # FIXME: Extract to a helper and use!
  #def self.toggleable_window(name)
  #  define_method "on_menu_windows_#{name.to_s}" do |event|
  #    hook = instance_variable_get("@#{name.to_s}_window")
  #    hook.send(hook.visible? ? :hide : :show)
  #  end
  #end
  #toggleable_window :map_tree
  #toggleable_window :settings

  # Windows -> Tileset
  def on_menu_windows_tileset(event)
    if @tileset_window.visible?
      @tileset_window.hide
    else
      @tileset_window.show
    end
  end

  # Windows -> Layer
  def on_menu_windows_layer(event)
    if @layer_window.visible?
      @layer_window.hide
    else
      @layer_window.show
    end
  end

  # Windows -> Console
  def on_menu_windows_console(event)
    if @console_window.visible?
      @console_window.hide
    else
      @console_window.show_all
    end
  end

  # Help -> About
  def on_menu_help_about(event)
    ad                    = AboutDialog.new
    ad.copyright          = "Copyright © #{Time.now.year} The OpenRubyRMK Team"
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

  def on_tool_selection_rect(widget)
    $app.state[:core][:selection_mode] = :rectangle
  end

  def on_tool_selection_magic(widget)
    $app.state[:core][:selection_mode] = :magic
  end

  def on_tool_selection_free(widget)
    $app.state[:core][:selection_mode] = :freehand
  end

  def on_tool_objects_edit(widget)
    $app.state[:core][:objects_mode] = :edit
  end

  def on_tool_objects_character(widget)
    $app.state[:core][:objects_mode] = :character
  end

  def on_tool_objects_free(widget)
    $app.state[:core][:objects_mode] = :free
  end

  ########################################
  # Helpers

  # Enable/Disable menu entries to reflect the operations possible
  # on +project+ (which may be +nil+ if no project is loaded).
  def update_menu_entries(project)
    if project
      menu_items[:file_new].sensitive              = false
      menu_items[:file_open].sensitive             = false
      menu_items[:file_save].sensitive             = true
      menu_items[:file_test].sensitive             = true
      menu_items[:file_package].sensitive          = true
      menu_items[:edit_resources].sensitive        = true
      menu_items[:edit_project_settings].sensitive = true
      menu_items[:edit_categories].sensitive       = true
      menu_items[:edit_templates].sensitive        = true

      @tools[:general][:new].sensitive  = false
      @tools[:general][:open].sensitive = false
      @tools[:general][:save].sensitive = true
    else
      menu_items[:file_new].sensitive              = true
      menu_items[:file_open].sensitive             = true
      menu_items[:file_save].sensitive             = false
      menu_items[:file_test].sensitive             = false
      menu_items[:file_package].sensitive          = false
      menu_items[:edit_resources].sensitive        = false
      menu_items[:edit_project_settings].sensitive = false
      menu_items[:edit_categories].sensitive       = false
      menu_items[:edit_templates].sensitive        = false

      @tools[:general][:new].sensitive  = true
      @tools[:general][:open].sensitive = true
      @tools[:general][:save].sensitive = false
    end
  end

  # Check the active layer’s type and enable/disable the corresponding
  # menu entries and toolbar tools.
  def update_layer_tools
    layer = $app.state[:core][:map].get_layer($app.state[:core][:z_index])

    # Firrst disable everything
    @tools[:selection].each_value{|tool| tool.sensitive = false}
    @tools[:objects].each_value{|tool| tool.sensitive = false}

    # Now enable the fitting tools
    case layer
    when TiledTmx::TileLayer
      @tools[:selection].each_value{|tool| tool.sensitive = true}
    when TiledTmx::ObjectGroup
      @tools[:objects].each_value{|tool| tool.sensitive = true}
    when TiledTmx::ImageLayer
      # TODO
    else
      raise("[BUG] Unsupported layer type: #{layer.inspect}")
    end

  end

end
