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
  # This model is always layouted in two columns: The first one
  # being a String column for the map name, the second one an
  # Integer column for the Map ID. Use the usual TreeStore
  # methods to access them (index 0 => name, index 1 => ID).
  class MapTreeStore < TreeStore

    # Create a new instance of this class, mirroring +project+’s
    # map tree. If +project+ is +nil+, the result simply is an
    # empty store, so you can easily pass the currently active
    # object to this method, even if no project is active currently.
    def initialize(project)
      super(String, Integer) # Map name, Map ID
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
      row[0] = map[:name]
      row[1] = map.id
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
    @storage  = MapTreeStore.new($app.project)
    @map_tree = TreeView.new(@storage)
    $app.observe(:project_changed) do |event, project|
      @storage = MapTreeStore.new(project)
      @map_tree.model = @storage
    end

    # Lay out the tree view.
    @map_tree.selection.mode = SELECTION_SINGLE
    name_renderer            = CellRendererText.new
    id_renderer              = CellRendererText.new
    name_col                 = TreeViewColumn.new("Map name", name_renderer, text: 0) # model[0] => Map name
    id_col                   = TreeViewColumn.new("Map ID", id_renderer, text: 1)     # model[1] => Map ID
    @map_tree.append_column(name_col)
    @map_tree.append_column(id_col)
  end

  def create_layout
    add(@map_tree) # We only have a single widget, so it may occupy all available window space
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  ########################################
  # Event handlers

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
