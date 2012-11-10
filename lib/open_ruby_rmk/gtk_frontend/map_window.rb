# -*- coding: utf-8 -*-

# The window containing the map tree. Note that a MapWindow
# cannot be destroyed by the user; attempting to close it will
# effectively just hide the window, so it is easy to later
# re-display it.
class OpenRubyRMK::GTKFrontend::MapWindow < Gtk::Window
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::Backend

  # GTK TreeView storage model for storing a project’s
  # map tree. To keep it in sync with the actual map tree
  # in the Projcet instance, we use its observing functionality.
  #
  # This model is always layouted in three columns: The
  # Backend::Map instance wrapped, the map’s ID and the
  # map’s name. The latter two values may seem redundant as
  # they’re available from the Map instance directly, but
  # they are there for convenience so we can fill the
  # TreeView’s view columns with ruby-gtk’s native (→ C)
  # methods without having to resort to virtual columns.
  class MapTreeStore < TreeStore

    # Create a new instance of this class, mirroring +project+’s
    # map tree. If +project+ is +nil+, the result simply is an
    # empty store, so you can easily pass the currently active
    # object to this method, even if no project is active currently.
    def initialize(project)
      super(OpenRubyRMK::Backend::Map, Integer, String) # Map, Map ID, Map name
      @project = project

      # Spy on the project, so we can act accordingly if
      # its maps change (if the project is +nil+, this is
      # and will always be an empty store (b/c there’s
      # no active project, which would have to be loaded
      # first, causing another instance of this class to
      # be created), hence there’s no need for an observer
      # then).
      @project.add_observer(self, :project_changed) if @project

      rebuild_map_tree!
    end

    # Triggered by the observed project whenever an event
    # occurs. However, as the method name indicates, only
    # map-related events will be processed by it.
    def project_changed(event, *args)
      case event
      when :root_map_added then raise("TODO")
      end
    end

    # Erases all entries from the map storage, then
    # completely resynchonises it to the map tree found
    # in the wrapped Backend::Project instance.
    def rebuild_map_tree!
      clear
      return unless @project # nil if no project is opened currently

      @project.root_maps.each do |root_map|
        traverse_map(root_map)
      end
    end

    private

    # Recursive helper method for #rebuild_map_tree! that adds
    # a single map to the internal storage tree, then repeates
    # the process for all child maps found.
    def traverse_map(map, parent = nil)
      row = append(parent)
      row[0] = map
      row[1] = map.id
      row[2] = map[:name]
      map.children.each{|child_map| traverse_map(child_map, map)}
    end

  end

  # Creates a new MapWindow. Pass in the parent window you want
  # to make this window a helper window of.
  def initialize(parent)
    super()
    set_default_size 200, 300

    self.type_hint     = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title         = t.windows.map_tree.title

    create_widgets
    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    # Create the map hierarchy widget and assign it the
    # map storage for the current project; if the current
    # project changes, resync it with the new project’s
    # map tree storage.
    @map_tree = TreeView.new(MapTreeStore.new($app.project))
    $app.observe(:project_changed) do |event, project|
      @map_tree.model = MapTreeStore.new(project)
    end

    # Lay out the tree view.
    @map_tree.selection.mode = SELECTION_SINGLE
    name_renderer            = CellRendererText.new
    id_renderer              = CellRendererText.new
    name_col                 = TreeViewColumn.new(t.windows.map_tree.labels.map_name, name_renderer, text: 2) # model[2] => Map name
    id_col                   = TreeViewColumn.new(t.windows.map_tree.labels.map_id, id_renderer, text: 1)     # model[1] => Map ID
    @map_tree.append_column(id_col)
    @map_tree.append_column(name_col)

    @add_button            = Button.new
    @del_button            = Button.new
    @settings_button       = Button.new

    @add_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("plus.png").to_s))
    @del_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("minus.png").to_s))
    @settings_button.add(Gtk::Image.new(OpenRubyRMK::GTKFrontend::ICONS_DIR.join("gear.png").to_s))

    # On startup, when no projects are loaded, these
    # buttons are disabled.
    @add_button.sensitive      = false
    @del_button.sensitive      = false
    @settings_button.sensitive = false

    # Enable/Disable buttons depending on the project state
    $app.observe(:project_changed) do |event, project|
      [@add_button, @del_button, @settings_button].each do |button|
        button.sensitive = !!project
      end
    end
  end

  def create_layout
    t = VBox.new(false, $app.space).tap do |vbox|
      b = HBox.new(false, $app.space).tap do |row|
        row.pack_end(@settings_button, false)
        row.pack_end(@del_button, false)
        row.pack_end(@add_button, false)
      end

      b.border_width = $app.space
      vbox.pack_start(b, false)
      vbox.pack_start(@map_tree, true, true)
    end

    add(t)
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
    @settings_button.signal_connect(:clicked, &method(:on_settings_button_clicked))
  end

  ########################################
  # Event handlers

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

  def on_add_button_clicked(event)
  end

  def on_del_button_clicked(event)
  end

  def on_settings_button_clicked(event)
    return unless @map_tree.cursor[0] # if no path is available, nothing is selected and we cannot do anything.
    map = @map_tree.model.get_iter(@map_tree.cursor[0])[0] # model[0] => Map instance

    msd = OpenRubyRMK::GTKFrontend::MapSettingsDialog.new(map)
    msd.run
  end

end
