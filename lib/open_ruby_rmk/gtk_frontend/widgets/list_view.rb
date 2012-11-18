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
  def initialize
    super(Gtk::ListStore.new(String))

    item_renderer = Gtk::CellRendererText.new
    item_column   = Gtk::TreeViewColumn.new("", item_renderer, text: 0) # model[0] => item text
    append_column(item_column)

    self.rules_hint      = true
    self.headers_visible = false
    selection.mode       = Gtk::SELECTION_SINGLE
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
    return nil unless cursor[0] # If no treepath is available, nothing is selected
    model.get_iter(cursor[0])[0]
  end

end
