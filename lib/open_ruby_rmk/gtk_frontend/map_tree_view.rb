# -*- coding: utf-8 -*-

# The widget responsible for drawing the map tree. This is
# basically a Gtk:TreeView with some layout added, and,
# most importantly, is by default associated with a model,
# namely MapTreeView::MapTreeStore, which automatically
# reflects the state of any given Backend::Project instance.
# This way, you don’t have to worry about associating the
# TreeView widget with a model and layouting it. Just
# instanciate this class and you’re done.
#
# Note MapTreeView currently always initialises the associated
# model with the globally selected project, so currently it
# isn’t possible to have two separate MapTreeView widgets that
# represent different projects. This allows the widget to
# register itself as an observer to the global App instance
# and automatically re-initialise the internal storage model
# with a new project if the globally selected project changes.
class OpenRubyRMK::GTKFrontend::MapTreeView < Gtk::TreeView
  include Gtk
  include R18n::Helpers

  # GTK TreeView storage model for storing a project’s
  # map tree. To keep it in sync with the actual map tree
  # in the Project instance, we use its observing functionality.
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
      # be created), hence there’s no need for observers
      # then).
      if @project
        @project.add_observer(self, :project_changed)
        @project.root_maps.each{|root_map| root_map.traverse(true){|map| map.add_observer(self, :map_property_changed)}}
      end

      rebuild_map_tree!
    end

    # Triggered by the observed project whenever an event
    # occurs. However, as the method name indicates, only
    # map-related events will be processed by it.
    def project_changed(event, emitter, info)
      case event
      when :root_map_added then raise(NotImplementedError, "TODO")
      end
    end

    # Triggered by any observed map when its properties change.
    def map_property_changed(event, emitter, info)
      return unless event == :property_changed
      return unless info[:property] == "name"

      # OK some map’s name has changed. Find the data model
      # row that corresponds with the changed map and update
      # that row’s name entry.
      each do |model, path, iter|
        if iter[0] == emitter    # model[0] => Map instance
          iter[2] = info[:value] # model[2] => Map name
          break
        end
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

  # Creates a new MapTreeView widget for the globally
  # selected project, automatically updating the internal
  # storage model if that globally selected project changes.
  def initialize
    super(MapTreeStore.new($app.project))
    $app.observe(:project_changed) do |event, emitter, info|
      set_model(MapTreeStore.new(info[:project]))
    end

    name_renderer            = CellRendererText.new
    id_renderer              = CellRendererText.new
    name_col                 = TreeViewColumn.new(t.windows.map_tree.labels.map_name, name_renderer, text: 2) # model[2] => Map name
    id_col                   = TreeViewColumn.new(t.windows.map_tree.labels.map_id, id_renderer, text: 1)     # model[1] => Map ID
    append_column(id_col)
    append_column(name_col)

    selection.mode           = SELECTION_SINGLE
  end

  # Returns the Backend::Map pointed to by the TreeView’s
  # current selection. If there’s no selection, returns
  # +nil+.
  def selected_map
    return nil unless cursor[0] # if no path is available, nothing is selected
    model.get_iter(cursor[0])[0] # model[0] => Map instance
  end

end
