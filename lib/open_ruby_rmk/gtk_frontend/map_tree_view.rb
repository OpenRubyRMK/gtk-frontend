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
  #
  # Before digging into the code of this class you are
  # better off understanding how Gtk::TreeIter objects
  # work, because some operations use its lowlevel
  # iteration interface rather than just calling
  # TreeStore#each.
  class MapTreeStore < TreeStore

    # Create a new instance of this class, mirroring +project+’s
    # map tree. If +project+ is +nil+, the result simply is an
    # empty store, so you can easily pass the currently active
    # object to this method, even if no project is active currently.
    def initialize(project)
      super(OpenRubyRMK::Backend::Map, Integer, String) # Map, Map ID, Map name
      @project = project

      # Special observer that doesn’t need to be deleted since we always
      # have a strong single relationship to this one project. All other
      # observers are deletable by #delete_observers.
      @project.add_observer(self, :project_changed) if @project

      rebuild_map_tree!
    end

    # Triggered by the observed project whenever an event
    # occurs. However, as the method name indicates, only
    # map-related events will be processed by it.
    def project_changed(event, emitter, info)
      case event
      when :root_map_added   then rebuild_map_tree!
      when :root_map_removed then rebuild_map_tree!
      end
    end

    # Triggered by any observed map when it changes somehow
    def map_changed(event, emitter, info)
      case event
      when :property_changed
        return unless info[:property] == "name" # We’re only interested in this property as we display it

        # OK some map’s name has changed. Find the data model
        # row that corresponds with the changed map and update
        # that row’s name entry.
        find_iter_for(emitter){|iter| iter[2] = info[:new_value]} # model[2] => Map name
      when :child_added
        # Resynchronise the affected part of the map tree.
        rebuild_map_tree!(emitter)
      when :child_removed
        # Delete the affected part of the map tree.
        find_iter_for(emitter){|iter| untraverse_row(iter)}
      end
    end

    # Erases part or all of the map storage (including observers),
    # then resynchronises the selected part with what is to be found
    # in the wrapped project instance. Does nothing if we wrap the
    # +nil+ project.
    # == Parameters
    # [start_map (nil)]
    #   The Backend::Map instance to start rebuilding at. Note this map
    #   itself (and its corresponding row) is left untouched, i.e. this
    #   method only operates on the children of it. +nil+ means to
    #   resynchronise the entire tree (including root maps).
    def rebuild_map_tree!(start_map = nil)
      return unless @project # nil if no project is opened currently and we’re wrapping the nil project

      if start_map
        # Find the iter for the start map, remove all its children
        # and rebuild the map tree from that iter/map combination
        # on downwards. DANGER: Low-level GTK iteration manipulation!
        find_iter_for(start_map) do |iter|
          if iter.has_child?
            child_iter = iter.first_child
            untraverse_row(child_iter) while iter_is_valid?(child_iter)
          end

          # Rebuild all child trees for this map.
          start_map.children.each do |map|
            traverse_map(map, iter)
          end
        end
      else
        # Since we want to remove all rows, we can take a neat shortcut
        # to delete all the observers:
        each{|iter| iter[0].delete_observer(self)}
        clear # Now erase the entire storage

        # Then rebuild all child trees for each root map.
        @project.root_maps.each do |root_map|
          traverse_map(root_map)
        end
      end
    end

    # Recursively searches through the storage and tries
    # to find the row that corresponds to +target_map+.
    # If one is found, it is yielded to the block.
    # == Parameters
    # [target_map]
    #   The Backend::Map instance to look for.
    # == Return value
    # The return value of your block.
    # == Remarks
    # Gtk::TreeIter objects are very short-lived objects.
    # They wouldn’t be valid after TreeView#each returns,
    # so you have to do you work with them in the block
    # supplied to this method, which is then called inside
    # the actual iteration where the TreeIter object is
    # valid. Adding/removing rows inside the block is fine
    # and won’t confuse GTK.
    def find_iter_for(target_map)
      each do |model, path, iter|
        if iter[0] == target_map # model[0] => Map instance
          break(yield(iter))
        end
      end
    end

    private

    # Recursive helper method for #rebuild_map_tree! that adds
    # a single map to the internal storage tree, adds an observer
    # for it and then repeates the process for all the map’s child
    # maps.
    def traverse_map(map, parent_row = nil)
      # Create the new row for the map
      row = append(parent_row)
      row[0] = map
      row[1] = map.id
      row[2] = map[:name]

      # Ensure we get notified when this map changes
      map.add_observer(self, :map_changed)

      # Repeat the process for each child map
      map.children.each{|child_map| traverse_map(child_map, row)}

      # Return something senseless that has no references to us
      nil
    end

    # Counterpart to #traverse_map. It deletes the observer
    # set on the map pointed to by +row+ and then deletes
    # that row from the storage, starting at the downmost
    # leafes of the iterator tree and recursively going
    # upwards.
    def untraverse_row(row)
      # Get the Map instance out of the row
      map = row[0]

      # We are not interested in this map anymore
      map.delete_observer(self)

      # Repeat the process for each child row
      # DANGER! Low-level GTK iterator manipulation!
      if row.has_child?
        child_iter = row.first_child
        until child_iter == iter_first # End of children reached
          untraverse_row(child_iter)
          child_iter.next!
        end
      end

      # Remove this leaf of the tree
      remove(row)

      # Return something senseless that has no references to us
      nil
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
    self.enable_tree_lines   = true
  end

  # Returns the Backend::Map pointed to by the TreeView’s
  # current selection. If there’s no selection, returns
  # +nil+.
  def selected_map
    return nil unless cursor[0] # if no path is available, nothing is selected
    model.get_iter(cursor[0])[0] # model[0] => Map instance
  end

end
