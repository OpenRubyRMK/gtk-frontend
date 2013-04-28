# -*- coding: utf-8 -*-

# Mixin module for some useful methods regarding the lookup of icon
# paths. Always typing out the full
#
#   OpenRubyRMK::GTKFrontend::ICONS_DIR.join("path1", "path2", "file.svg")
#
# is quite annoying, so instead this module defines some little helper
# methods that do exactly this for you, plus instanciating the appropriate
# Gdk and Gtk classes if requested.
module OpenRubyRMK::GTKFrontend::Helpers::Icons

  # Convenience method for finding out paths below
  # <orrroot>/data/icons. The return value is
  # a Pathname instance. +size+ determines the subdirectory
  # to use; "svg" are the freely-scalable files.
  #   icon_path("ui/myicon.svg")
  #   icon_path("ui/myicon.png", "16x16")
  def icon_path(path, size = "svg")
    OpenRubyRMK::GTKFrontend::ICONS_DIR.join(size, *path.split("/"))
  end

  # Creates a Gdk::Pixbuf from the given icon file relative
  # to <orrroot>/data/icons.
  #   icon_pixbuf("ui/myicon.svg", width: 32)
  # The hash argument accepts the :width and :height options,
  # which are passed through as the appropriate values for
  # Gdk::Pixbuf.new. They’re both set to -1 by default, which
  # will make Gdk use the image’s native dimensions. Note that
  # when you request a PNG rather than an SVG you must specify
  # both width and height in order to make #icon_path find the
  # correct directory for your files.
  def icon_pixbuf(path, hsh = {})
    hsh[:width]  ||= -1
    hsh[:height] ||= hsh[:width]

    if hsh[:width] > 0 && hsh[:height] > 0
      ipath = icon_path(path, "#{hsh[:width]}x#{hsh[:height]}")
    else
      ipath = icon_path(path)
    end

    Gdk::Pixbuf.new(ipath.to_s, hsh[:width], hsh[:height])
  end

  # Same as #icon_pixbuf, but also wraps a Gtk::Image
  # around the generated Gdk::Pixbuf object.
  def icon_image(path, hsh = {})
    Gtk::Image.new(icon_pixbuf(path, hsh))
  end

end
