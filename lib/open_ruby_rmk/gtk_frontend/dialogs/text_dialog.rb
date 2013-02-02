# -*- coding: utf-8 -*-
#
# A simple text-input dialog that requests the user to enter
# a single line of text. Use it like this:
#
#   t = TextDialog.new(your_window, "Input something", "Enter something here:")
#   t.run
#   puts "The user entered '#{t.text}'."
#
# The +text+ attribute will contain the entered text after
# the dialog has been closed via the OK button; if cancel was
# pressed, +text+ will be +nil+. Note the user might enter
# nothing and press OK, in which case +text+ will be an
# empty string.
class OpenRubyRMK::GTKFrontend::Dialogs::TextDialog < Gtk::Dialog
  include Gtk

  # The text entered by the user.
  attr_reader :text

  # Creates a new TextDialog modal to +parent_window+,
  # with the given +title+ showing the given +message+.
  def initialize(parent_window, title, message)
    super(title,
          parent_window,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 200, 100

    self.transient_for = parent
    self.title         = title

    @message = message
    @text    = nil

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @label = Label.new(@message)
    @entry = Gtk::Entry.new
  end

  def create_layout
    vbox.spacing = $app.space

    vbox.pack_start(@label)
    vbox.pack_start(@entry)
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      @text = @entry.text
    end

    destroy
  end

end
