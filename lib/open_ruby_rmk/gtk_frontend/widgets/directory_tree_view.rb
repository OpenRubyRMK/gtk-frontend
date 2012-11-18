# -*- coding: utf-8 -*-

# This is a widget for displaying a directory tree. It’s a
# normal Gtk::TreeView with the model part already being
# included in it (the DirectoryTreeStore class) so you don’t
# have to worry about the interna. It also registers itself
# as an observer to the currently selected project, so that
# when the project’s resources get reloaded, the widget
# rebuilds all internal buffers and rebuilds itself.
class OpenRubyRMK::GTKFrontend::Widgets::DirectoryTreeView < Gtk::TreeView
  include Gtk

  # GTK TreeView storage model for storing a directory
  # tree. It consists of two columns of type Pathname and
  # String, which both represent the path on the filesystem
  # pointed to by a row. The Pathname column contains the
  # path pointed to by a row as an absolute path as a
  # Pathname instance, whereas the String column contains
  # only the basename (as a string).
  # By making the latter column a String, we can make use
  # of GTK’s default text cell renderer, which is much more
  # performant than creating a virtual column just for calling
  # +to_s+ on a Pathname.
  class DirectoryTreeStore < TreeStore

    # The root path this model traverses from.
    attr_reader :root_path

    # Create a new instance of this class. Pass in the
    # root path from which you want this model to
    # traverse from. If +store_files+ is +true+, the model
    # will also recognise files (and not only directories)
    # on the file system.
    def initialize(root_path, store_files = false)
      super(Pathname, String)
      @root_path = Pathname.new(root_path)
      @store_files = store_files

      rebuild_directory_tree!
    end

    private

    # Clears the internal buffers and rebuilds the
    # entire model from what is found on disk.
    def rebuild_directory_tree!
      clear
      traverse_directory(@root_path)
    end

    # Helper method for #rebuild_directory_tree!. Recursively
    # adds a new row for +path+ to +parent_row+.
    def traverse_directory(path, parent_row = nil)
      return if !@store_files and !path.directory?

      row = append(parent_row)
      row[0] = path
      row[1] = path.basename.to_s

      return unless path.directory? # Can only traverse directories
      path.each_child{|child_path| traverse_directory(child_path, row)}
    end

  end

  # Creates a new instance of this widget.
  def initialize(root_path)
    super(DirectoryTreeStore.new(root_path))

    path_renderer          = CellRendererText.new
    path_column            = TreeViewColumn.new("Path", path_renderer, text: 1) # model[1] => path as a string
    append_column(path_column)

    selection.mode         = SELECTION_SINGLE
    self.enable_tree_lines = true
  end

  # Returns the path pointed to by the currently selected
  # row. If no row is selected currently, returns +nil+.
  def selected_path
    return nil unless cursor[0]  # If no treepath is available, nothing is selected
    model.get_iter(cursor[0])[0] # model[0] => Pathname instance
  end

end

# Widget for displaying the directory tree below the current
# project’s +resources+ directory. It automatically rebuilds
# itself when the project’s resources get reloaded.
class OpenRubyRMK::GTKFrontend::Widgets::ResourceDirectoryTreeView < OpenRubyRMK::GTKFrontend::Widgets::DirectoryTreeView

  def initialize
    super($app.project.paths.resources_dir)
    $app.project.observe(:resources_reloaded) do
      model.rebuild_directory_tree!
    end
  end

end
