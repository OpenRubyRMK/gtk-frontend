# A Gtk::SourceView, configured for editing Ruby code.
class OpenRubyRMK::GTKFrontend::Widgets::RubySourceView < Gtk::SourceView

  # Create a new RubySourceView; all arguments are delegated
  # to Gtk::SourceView.new.
  def initialize(*)
    super

    self.modify_font(Pango::FontDescription.new("monospace"))

    self.show_line_numbers = true
    self.insert_spaces_instead_of_tabs = true
    self.indent_width = 2
    self.show_right_margin = true
    self.right_margin_position = 80

    self.buffer.language = Gtk::SourceLanguageManager.new.get_language("ruby")
    self.buffer.highlight_syntax = true
    self.buffer.highlight_matching_brackets = true
  end

end
