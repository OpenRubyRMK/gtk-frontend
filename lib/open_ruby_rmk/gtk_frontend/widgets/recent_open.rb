# -*- coding: utf-8 -*-

# Simple menu displaying a list of the last opend projects.
# This is basically just a Gtk::RecentChooserMenu with 
# preset options like a filter or the visible items.
class OpenRubyRMK::GTKFrontend::Widgets::RecentOpenMenu < Gtk::RecentChooserMenu
  def initialize(parent, *args)
    super(parent, *args)
    self.limit = 5
    self.show_not_found = false
    self.filter = Gtk::RecentFilter.new.add_pattern('*.rmk')
  end
end