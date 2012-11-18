# -*- coding: utf-8 -*-
# A button with an image linking to a URI.
#
# This widget uses a small hack to avoid the creating of an
# entirely new widget: Gtk::LinkButton alraedy adds a
# Label as the button’s child showing the target URI,
# so adding a new child is impossible. Instead, we remove
# the label from the button and place an image on it instead.
class OpenRubyRMK::GTKFrontend::Widgets::ImageLinkButton < Gtk::LinkButton

  # Create a new instance of this widget. +uri+ is the
  # target URI to open when the button gets clicked,
  # +image+ is the Gtk::Pixbuf to draw onto the button.
  # Note that if you leave it out, you’ll get the default
  # behaviour of Gtk::LinkButton, which is to display a
  # label with the URI on the button. You can however
  # later specify an image via #image=; this will remove
  # whatever is currently in the button (be it label or
  # image) and set it to a new image.
  def initialize(uri = "", image = nil)
    super(uri)
    self.image= image if image
  end

  # Sets the image of the button to the given
  # Gdk::Pixbuf.
  def image=(pixbuf)
    # Delete whatever is currently in the button
    remove(children.first)

    # Add the image as the child.
    add(Gtk::Image.new(pixbuf))
  end

end
