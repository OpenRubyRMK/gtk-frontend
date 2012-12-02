# -*- coding: utf-8 -*-

# Dialog window for previewing a resource of any type.
class OpenRubyRMK::GTKFrontend::Dialogs::ResourcePreviewDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  # Creates a new instance of this class. Pass in the parent window and the
  # Backend::Resource you want to preview.
  def initialize(parent, resource)
    super(t.dialogs.resource_preview.title,
          parent,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_NONE])

    @resource = resource

    set_default_size(200, 200)

    if resource.graphic?
      create_graphic
    elsif resource.video?
      create_video
    elsif resource.audio?
      create_audio
    else
      raise(NotImplementeError, "Don't know how to preview this yet.")
    end    
  end

  # Shows all child widgets, then calls the superclass’
  # method. Automatically destroys the dialog prior
  # to returning.
  def run(*)
    show_all
    super
    destroy
  end

  private

  def create_graphic
    @pixbuf   = Gdk::Pixbuf.new(@resource.path.to_s)
    @scroller = ScrolledWindow.new
    @canvas   = Layout.new

    @canvas.set_size(@pixbuf.width, @pixbuf.height)
    @canvas.signal_connect(:expose_event) do |*|
      cc = @canvas.bin_window.create_cairo_context
      cc.set_source_pixbuf(@pixbuf)
      cc.paint
    end

    @scroller.add(@canvas)
    vbox.add(@scroller)
  end

  def create_video
  end

  def create_audio
  end

end
