# A label that aligns left in its available space.
class OpenRubyRMK::Backend::LeftLabel < Gtk::Label

  def initialize(*)
    super
    set_alignment(0, 0)
  end

end
