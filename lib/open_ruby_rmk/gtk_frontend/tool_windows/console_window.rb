# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::ToolWindows::ConsoleWindow < Gtk::Window
  include Gtk

  # RIPL plugin intended to be run as a separate-thread RIPL that
  # writes input to a RubyTerminal widget in asynchronous mode.
  # To process input, store it in the RIPL thread’s thread-local
  # variable :input (an array of strings) and call #run on the
  # RIPL thread. The thread-local variable :terminal must contain
  # the RubyTerminal widget RIPL shall write to.
  module RiplRubyTerminalInput

    # RIPL hook. Waits for user input, then returns it.
    def get_input
      terminal.async_prompt(prompt)

      # The user may have entered something and pressed [RETURN]
      # while we were running. In this case, the thread-local
      # array :input isn’t empty, but contains the user’s extra
      # input. If this is the case, we’ll just use it, otherwise
      # we wait until the user presses [RETURN], in which case
      # we are waked up via #run anyway.
      sleep if Thread.current[:input].empty?

      # Regardless how we got the line of input, hand it over
      # to RIPL.
      Thread.current[:input].shift
    end

    # RIPL hook. Feeds +result+ to the terminal.
    def print_result(result)
      terminal.feed(format_result(result))
    rescue StandardError, SyntaxError
      terminal.feed("ripl: #{MESSAGES['print_result']}:", format_error($!))
    end

    # RIPL hook. Feeds +err+ to the terminal.
    def print_eval_error(err)
      terminal.feed(format_error(err))
    end

    # RIPL hook. Basically the same as RIPL’s default
    # #format_result, but converts the newlines to the
    # terminal-friendly CR-LF format and also appends
    # a trailing newline.
    def format_result(result)
      super.gsub("\n", "\r\n") + "\r\n"
    end

    # RIPL hook. Basically the same as RIPL’s default
    # #format_result, but converts the newlines to the
    # terminal-friendly CR-LF format and also appends
    # a trailing newline.
    def format_error(err)
      super(err).gsub("\n", "\r\n") + "\r\n"
    end

    private

    # Convenience method for accessing the thread-local variable
    # for the RubyTerminal instance.
    def terminal
      Thread.current[:terminal]
    end

  end

  # Include the terminal widget adapter in RIPL and ensure
  # that when it crashes, the whole application crashes.
  Thread.abort_on_exception = true
  Ripl::Shell.include(RiplRubyTerminalInput)

  def initialize(parent)
    super()
    set_default_size(400, 300)

    self.type_hint = Gdk::Window::TYPE_HINT_UTILITY
    self.transient_for = parent
    self.title = "Debugging console"

    # The widgets must be created prior to initialising
    # the RIPL thread, hence this is done here and not
    # together with #create_layout and #setup_event_handlers
    # as usually done.
    create_widgets

    # Run RIPL in a separate thread so the GUI stays repsonsive
    # while input is evaluated.
    @ripl_thread = Thread.new do
      # We need the terminal to send input there
      Thread.current[:terminal] = @terminal
      Thread.current[:input]    = []

      # Execute RIPL in a loop, so that calling `exit'
      # will just restart it (but also hide the window
      # as the user might expect this).
      loop do
        Ripl.config[:readline] = false
        Ripl.start
        hide
      end
    end

    create_layout
    setup_event_handlers
  end

  private

  def create_widgets
    # Create the terminal widget in asynchronous mode
    @terminal = OpenRubyRMK::GTKFrontend::Widgets::RubyTerminal.new do |t|
      #t.debug_terminal = true

      t.on :enter do |line|
        @ripl_thread[:input] << line
        @ripl_thread.run # Notify the RIPL thread that input is available (does nothing if it is currently evaluating)

        "" # Print nothing, we’re running asynchronously
      end

    end
  end

  def create_layout
    add(@terminal)
  end

  def setup_event_handlers
    signal_connect(:delete_event, &method(:on_delete_event))
  end

  def on_delete_event(*)
    hide
    true # Do not destroy the window, just hide it
  end

end
