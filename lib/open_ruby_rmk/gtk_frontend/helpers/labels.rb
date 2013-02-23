# -*- coding: utf-8 -*-
# Helper methods for coping with Gtk::Label instances.
module OpenRubyRMK::GTKFrontend::Helpers::Labels

  # Creates a onelne Gtk::Label for <tt>str.to_s</tt> and
  # sets it’s space alignment (the behaviour towards surrounding
  # space) to left-align. Use this method to label input widgets.
  # The return value is a Gtk::Label instance than can directly
  # be used for Gtk::Box#pack_*.
  def label(str)
    l = Gtk::Label.new(str.to_s)
    l.xalign = 0
    l
  end

end
