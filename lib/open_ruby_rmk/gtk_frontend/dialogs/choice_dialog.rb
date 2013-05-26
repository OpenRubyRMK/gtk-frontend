# -*- coding: utf-8 -*-

# A simple dialog to query the user to choose between a given number
# of choices. Use it like this:
#
#   c = ChoiceDialog.new(your_window,
#                        "Choose something",
#                        "Choose one of the following options:",
#                         ["Choice 1", "Choice 2"])
#   c.run
#   puts "The user choose option #{c.selection}"
#
# After the user clicked the OK button, you can query the selected
# index for your choices array via #selection. However, if the
# user aborted the dialog, this will return nil. Also note that
# if you don’t force an initial selection with #selection= the user
# might not choose anything and press OK, also making #selection
# returning nil.
class OpenRubyRMK::GTKFrontend::Dialogs::ChoiceDialog < Gtk::Dialog
  include Gtk

  # Creates a new dialog modal to +parent_window+. For the
  # usage, see the class’ docs.
  def initialize(parent_window, title, message, choices)
    super(title,
          parent_window,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 200, 100

    self.transient_for = parent
    self.title = title

    @message = message
    @choices = choices
    @index   = nil

    raise(ArgumentError, "No choices.") if @choices.empty?

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

  # Returns the index of the selected item in the
  # choices for this combobox or nil if nothing
  # has been selected.
  def selection
    @index
  end

  # Set the selection to the given index in the
  # choices array.
  def selection=(index)
    @index = @box.active = index.to_int
  end

  private

  def create_widgets
    @label = Label.new(@message)
    @box = Gtk::ComboBox.new

    @choices.each{|choice| @box.append_text(choice)}
  end

  def create_layout
    vbox.spacing = $app.space
    vbox.pack_start(@label)
    vbox.pack_start(@box)
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      @index = @box.active
    else
      @index = nil
    end

    destroy
  end

end
