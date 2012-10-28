# -*- coding: utf-8 -*-

# Helper mixin module for making the creating of GTK menus easier.
# It allows you to compress this quite verbose and non-rubyish
# creation of a typic File menu:
#
#   menubar   = MenuBar.new
#   file_item = MenuItem.new("File")
#   file_menu = Menu.new
#   file_item.set_submenu(file_menu)
#   file_quit_item = MenuItem.new("Quit")
#   file_menu.append(file_quit_item)
#   file_quit_item.signal_connect(:activate){|event| ...}
#
# Into the following much more Ruby-like code:
#
#   menubar = MenuBar.new
#   menu menubar, "File" do |menu|
#     append_menu_item menu, "Quit"
#   end
#   menu_items[:quit].signal_connect(:activate){|event| ...}
#
# Submenus:
#
#   menu menubar, "File" do |menu|
#     menu menu, "Templates" do |templates_menu|
#       append_menu_item templates_menu, "Cool"
#       append_menu_item templates_menu, "Bad"
#    end
#  end
#  menu_items[:cool].signal_connect...
#  menu_items[:bad].signal_connect...
#
# If you don’t like the automatic identifier generation
# or have to override it, because you have multiple similarily
# named items, you can do so easily:
#
#   # ...
#   append_menu_item menu, "Quit", :file_quit
#   # ...
#   menu_items[:file_quit].signal_connect(:activate){|event| ...}
#
# To use it, just include it in your class:
#
#   class MyWindow < Gtk::Window
#     include OpenRubyRMK::GTKFrontend::MenuBuilder
#     # ...
#   end
module OpenRubyRMK::GTKFrontend::MenuBuilder

  # Initialises the internal menu item storage.
  # Hooks into the +initialize+ chain properly.
  def initialize(*) # :nodoc:
    super
    @__gtk_menu_items = {}
  end

  protected

  # call-seq:
  #   menu(menu_or_menubar, label){|menu, menu_main_item| ...}
  #
  # Adds a new menu to a given menu bar or menu
  # (the latter creating a submenu).
  # == Parameters
  # [menu_or_menubar]
  #   The Gtk::Menu or Gtk::MenuBar instance to
  #   attach the new menu to.
  # [label]
  #   The label to display on the menu item’s main
  #   item (i.e. the widget that must be clicked in
  #   order to make the actual menu visible).
  # [menu <block>]
  #   The created Gtk::Menu instance. Pass it to
  #   #append_menu_item to create items in it.
  # [menu_main_item <block>]
  #   The Gtk::MenuItem instance that holds +menu+. You
  #   most likely won’t need it.
  def menu(menu_or_menubar, label)
    # Create the menu and the menu item that
    # holds the menu, attach the former to
    # the latter.
    gtk_menu       = Gtk::Menu.new
    gtk_menu_item  = Gtk::MenuItem.new(label)
    gtk_menu_item.set_submenu(gtk_menu)
    menu_or_menubar.append(gtk_menu_item)

    # Execute the block.
    yield(gtk_menu, gtk_menu_item)
  end

  # Adds a new entry to a given menu with the
  # given label and adds it to the internal menu
  # item storage.
  # == Parameters
  # [menu]
  #   The menu to append to.
  # [label]
  #   The label to display on the menu item.
  # [name (<tt>label.downcase.to_sym</tt>)]
  #   The key to use for storing the item in the
  #   internal menu item storage. Derived from +label+
  #   if not given.
  # == Return value
  # The created Gtk::MenuItem instance.
  def append_menu_item(menu, label, name = label.downcase.to_sym)
    gtk_menu_item = Gtk::MenuItem.new(label)
    menu.append(gtk_menu_item)

    @__gtk_menu_items[name] = gtk_menu_item
  end

  # Appends a separator to +menu+. A separator is
  # the little sunken line that separates contextually
  # similar menu entry groups from one another.
  def append_menu_separator(menu)
    menu.append(Gtk::SeparatorMenuItem.new)
  end

  # Direct access to the internal menu item storage.
  # Index it with the keys you handed to the
  # #append_menu_item method in order to access the
  # created menu items, e.g. for attaching event
  # handlers.
  def menu_items
    @__gtk_menu_items
  end

end
