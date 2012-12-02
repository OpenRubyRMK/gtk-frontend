# -*- coding: utf-8 -*-

# Simple widget displaying a list of string items.
# This is basically just a Gtk::TreeView with an
# already associated model and rendering facilities,
# plus some convenience methods to hide the model
# part from the user when he doesn’t need to know
# about it.
#
# TODO: Extend this widget with remove, insert,
# etc. capabilities.
class OpenRubyRMK::GTKFrontend::Widgets::ListView < Gtk::TreeView

  # Create a new ListView widget.
  # == Parameter
  # [editable (false)]
  #   If this is true, allows the user to double-click on cells and
  #   edit them. If you enable this, be sure to set an event callback
  #   via #edit_cell.
  # == Return value
  # The newly created instance.
  def initialize(editable = false)
    super(Gtk::ListStore.new(String))

    @editable           = editable
    @cell_edit_callback = nil

    item_renderer = Gtk::CellRendererText.new
    item_column   = Gtk::TreeViewColumn.new("", item_renderer, text: 0) # model[0] => item text
    append_column(item_column)

    if @editable
      item_renderer.editable = true
      item_renderer.signal_connect(:edited, &method(:on_cell_edited))
    end

    self.rules_hint      = true
    self.headers_visible = false
    selection.mode       = Gtk::SELECTION_SINGLE
  end

  # Returns +true+ if the cells in this widget are editable.
  def editable?
    @editable
  end

  # Empties the entire list.
  def clear
    model.clear
  end

  # Appends an item to the list. +item+ will automatically
  # be converted to a string.
  def append(item)
    row = model.append
    row[0] = item.to_s
  end

  # Returns the currently selected item as a string,
  # or +nil+ if nothing is selected.
  def selected_item
    return nil unless cursor[0]  # If no treepath is available, nothing is selected
    model.get_iter(cursor[0])[0] # model[0] => item text
  end

  # Takes a (valid) Gtk::TreePath describing a row in the data model
  # and tranforms it into the actual Gtk::TreeIter for that row. Finally,
  # it retrieves the iter’s string value. If no fitting iter can be found,
  # returns +nil+.
  #
  # ...or for short, returns the string in the row represented by +path+.
  def path2string(path)
    iter = model.get_iter(path)
    return nil unless iter

    iter[0] # model[0] => item text
  end

  # Registers a callback for the cell editing event. The callback
  # will get passed three arguments: The Gtk::CellRendererText being
  # edited, the Gtk::TreePath representing the row being edited,
  # and the new value for the cell.
  def edit_cell(&block)
    @cell_edit_callback = block
  end

  private

  def on_cell_edited(cell, path, value)
    return unless @cell_edit_callback
    @cell_edit_callback.call(cell, path, value)
  end

end
