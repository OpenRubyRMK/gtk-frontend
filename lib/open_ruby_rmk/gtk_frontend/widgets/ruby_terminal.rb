# -*- coding: utf-8 -*-

# Special widget that allows you to provide a terminal-like interface
# to the user without having to spawn a new process, so that you can
# provide a facility to evaluate code in the context of your
# application. If you just want to have a termiinal for bash, zsh,
# or any other external shell, use Vte::Terminal directly and forget
# about this widget. This is more useful if you want to embed IRB
# (or the much easier to emped RIPL) inside your application.
#
# The widget registers for the VTE’s :commit event which is fired
# always when the user enters any kind of input into the terminal
# (control sequences like arrow keys or backspace included). The
# input is stored inside an internal cache which should always
# match with the currently edited line in the terminal; if
# [RETURN] is hit, that cache gets cleared (and a newline is
# outputted on the widget). When a control sequence arrives,
# the exact action taken depends on the control sequence, but
# generally you have to be very careful to not invalidate the
# internal cache so that visible characters and internal storage
# differ, leading to great confusion for the user.
#
# As a programmer using this widget, you probably don’t have to
# know about the above things, but it could prove useful if you
# experience unexplainable input interpretation. Probably the
# cache was bad, resulting in garbled commands being sent. You
# can always access the current value of the cache via the #cache
# getter, but to accurately inspect what’s going on, you probably
# want to set #debug_terminal to +true+. This will print out
# useful debugging information on $stdout when you interact with
# the widget, and if you found a bug, you should include the output
# of running the widget in debug mode.
#
# Actually using the widget is done by defining some callbacks that
# will be executed depending on the user’s interaction with the
# terminal. You can define these callbacks via the #on method,
# and a simple echo terminal may look like this:
#
#   RubyTerminal.new do
#     on :enter do |line|
#       "ECHO: #{line}"
#     end
#     on :prompt do
#       ">> "
#     end
#   end
#
# Everytime the prompt needs to be reprinted, the callback defined
# for :prompt will be executed, whose return value will then be
# fed into the terminal widget, making ">> " appear there and moving
# the cursor beyond that prompt. When the user has finished entering
# his command and presses [RETURN], :enter will be fired and the
# line (or rather, the current value of the internal cache which
# is hopefully equal to what is visible on the terminal widget) will
# be passed to the callback. The return value is printed onto the
# terminal widget (if you want to print while still processing,
# call the #feed method inherited from Vte::Terminal, but note you
# must then take care of moving the cursor), then :prompt is fired
# again and everything begins anew.
#
# The definable callbacks are as follows:
#
# [enter (line)]
#   Executed when the user presses [RETURN]. Gets passed the
#   line as completed by the user (without the prompt). The
#   return value is fed into the terminal (you may want to
#   add a trailing newline).
# [history_next]
#   Executed when the user presses [DOWN]. The return value
#   is fed into the terminal. TODO.
# [history_previous]
#   Executed when the user presses [UP]. The return value
#   is fed into the terminal. TODO.
# [prompt]
#   Executed when the prompt needs to be reprinted. The return
#   value is fed into the terminal widget.
#
# Note that the only callback you are required to implement is
# :enter, but depending on your use case you may want to define
# other callbacks as well.
#
# == Asynchronous mode
# By default, this widget runs in synchronous mode, i.e. after
# the user hits [RETURN], your callback is called, waited for,
# and then its return value is printed. Then the prompt is
# printed by firing the :prompt event and we’re waiting for user
# input again. This is easy, and probably you don’t need more.
# However, things get a little tricky when the entered commands
# take a long time to complete and you may want to display
# progress; that won’t work in synchronous mode, because while
# your command runs, the GUI event loop is blocked and the widget
# will not process any draw events until your command returns control
# to the event loop. To circumvent this, you can use this widget
# in <i>asynchronous mode</i>. Asynchronous mode behaves exactly
# like the synchronous one, with two important differences:
#
# 1. To enter asynchronous mode, your :enter callback must return
#    immediately after receiving and storing the input, returning
#    an empty string to the terminal.
# 2. Don’t define a callback for the :prompt event, because it would
#    get called immediately after your callback finishes, which is
#    undesired, because it returns (nearly) immediately.
#
# From this, we can deduce two further things: First and most importantly,
# to fulfill 1) we need threads (or another means of asynchronisity).
# Second, we have to print the prompt ourselves, because the default
# prompting mechanism doesn’t work and furthermore, the terminal can’t
# know when your asynchronous code has finished.
#
# While your asynchronous code runs, it most likely wants to output
# something onto the terminal. To do so, use the inherited #feed
# method, which will print the text you specify and advance the
# text cursor. Do *not* use this method to print the prompt, this
# will cause the next :enter event to receive garbage text containing
# whole or part of your prompt; instead, use #async_prompt which
# ensures that the terminal’s internal state stays clean.
class OpenRubyRMK::GTKFrontend::Widgets::RubyTerminal < Vte::Terminal

  # The VTE widget generates this character when the [DEL] key
  # is pressed.
  VTE_FORWARD_DELETE = "\e[3~"

  # The VTE widget generates this character when the [BACKSPACE]
  # key is pressed.
  VTE_REVERSE_DELETE = "\b"

  # The VTE widget generates this character when the [RETURN]
  # key is pressed.
  VTE_LINE_TERMINATOR = "\r"

  # The VTE widget generates this character then the [LEFT] arrow
  # key is pressed.
  VTE_CURSOR_MOVE_LEFT = "\e[D"

  # The VTE widget generates this character when the [RIGHT] arrow
  # key is pressed.
  VTE_CURSOR_MOVE_RIGHT = "\e[C"

  # The VTE widget generates this character when the [DOWN] arrow
  # key is pressed.
  VTE_CURSOR_MOVE_DOWN = "\e[B"

  # The VTE widget generates this character when the [UP] arrow
  # key gets pressed.
  VTE_CURSOR_MOVE_UP = "\e[A"

  # The VTE widget generates this character when the [HOME]
  # key is pressed.
  VTE_CURSOR_HOME = "\eOH"

  # The VTE widget generates this character when the [END]
  # key is pressed.
  VTE_CURSOR_END = "\eOF"

  # The current value of the cache. DO NOT CHANGE.
  attr_reader :cache

  # If this is true, this widget will print out various
  # debug infos on $stdout while running.
  attr_accessor :debug_terminal

  # Create a new instance of this class. If called with a block
  # that takes an argument, +self+ is passed into the block.
  # If the block takes no argument, it is evaluated in the context
  # of +self+, making it possible to call e.g. #on without an
  # explicit receiver. If no block is passed at all, well, then
  # no block is executed.
  # == Parameter
  # [font ("Monospace 14")]
  #   The font to use for the terminal, consisting of the
  #   font name and a font size.
  # == Return value
  #   The newly created widget.
  def initialize(font = "Monospace 14", &block)
    super()
    set_font(font, Vte::TerminalAntiAlias::FORCE_ENABLE)

    # Initialise internal state
    @debug_terminal = false
    @cache          = ""
    @prompt_length  = 0
    @callbacks      = {}

    # Register GTK event handlers
    signal_connect(:commit, &method(:on_commit))

    # If a block was given, use it to setup the
    # callback for the emulated process.
    if block
      if block.arity > 0
        yield(self)
      else
        instance_eval(&block)
      end
    end

    # The first thing a terminal must do is to display the prompt.
    draw_prompt
  end

  # Defines a callback for a certain event. See the class’
  # docs for a list of possible values for +event+.
  def on(event, &block)
    @callbacks[event] = block
  end

  # When using asynchronous mode, use this method to print
  # the prompt onto the terminal. It ensures the terminal’s
  # state to be clean, so that further :enter events won’t
  # get garbage strings.
  def async_prompt(str)
    feed(str)
    @prompt_length = str.chars.count
  end

  private

  # If a callback is registered for +event+, execute
  # it with the given arguments forwarded, then convert
  # the callback’s result into a string which is then
  # feeded into the terminal widget.
  # If no callback is registered, this method immediately
  # returns.
  def callback(event, *args)
    return "" unless @callbacks[event]
    debug("CALLBACK: #{event}")
    feed(@callbacks[event].call(*args).to_s)
  end

  # Like #callback, but doesn’t feed the callback’s result
  # into the terminal widget.
  def silent_callback(event, *args)
    return "" unless @callbacks[event]
    debug("SILENTCALLBACK: #{event}")
    @callbacks[event].call(*args).to_s
  end

  def on_commit(_, text, length)
    debug("TEXTCOMMIT: #{text.inspect}")
    case text
    when VTE_REVERSE_DELETE
      column, row = cursor_position
      target_index = column - @prompt_length - 1 # We want to delete to the left
      return if target_index < 0 # Beginning of line

      # Delete the target character from the cache
      @cache[target_index] = ""

      # We now overprint the target character on the widget
      # (\b below) with the rest of the line (plus a splace
      # so we don’t leave the last character unoverprinted).
      # After this, the cursor is at the end of the line; we
      # then move it back to the position where it was prior
      # to the deletion, plus one character further so we end
      # up left to the deletion position.
      rest = @cache[target_index..-1]
      output = "\b#{rest} "
      output.concat(VTE_CURSOR_MOVE_LEFT * (rest.chars.count + 1))
      feed(output)
    when VTE_FORWARD_DELETE
      column, row = cursor_position
      target_index = column - @prompt_length
      return if target_index >= @cache.chars.count # End of line

      # Delete the character from the cache
      @cache[target_index] = ""

      # Overprint with rest, move cursor to the previous
      # position. See the comments on VTE_REVERSE_DELETE
      # for a detailed explanation.
      rest = @cache[target_index..-1]
      output = "#{rest} " # \b required, cursor is already at the correct position
      output.concat(VTE_CURSOR_MOVE_LEFT * (rest.chars.count + 1))
      feed(output)
    when VTE_LINE_TERMINATOR
      feed("\r\n")
      callback :enter, @cache.dup # Asynchronous callbacks store this, which is bad when we clear it (race condition). So dup it.
      @cache.clear
      callback :prompt
    when VTE_CURSOR_MOVE_LEFT
      # Move cursor only to the left if not moving into
      # the prompt.
      column = cursor_position[0]
      return if column <= @prompt_length
      feed(text)
    when VTE_CURSOR_MOVE_RIGHT
      # Move cursor only to the right if not moving behind
      # the current line’s length.
      column = cursor_position[0]
      return if column >= @prompt_length + @cache.chars.count
      feed(text)
    when VTE_CURSOR_MOVE_UP
      callback :history_previous
    when VTE_CURSOR_MOVE_DOWN
      callback :history_next
    when VTE_CURSOR_HOME
      feed(VTE_CURSOR_MOVE_LEFT * (cursor_position[0] - @prompt_length))
    when VTE_CURSOR_END
      inline_pos = cursor_position[0] - @prompt_length
      feed(VTE_CURSOR_MOVE_RIGHT * (@cache.chars.count - inline_pos))
    else
      column = cursor_position[0]
      target_index = column - @prompt_length

      @cache.insert(target_index, text)

      output = @cache[target_index..-1]
      output.concat(VTE_CURSOR_MOVE_LEFT * (output.chars.count - 1))
      feed(output)
    end
    debug("[NEW CACHE: #{@cache.inspect}]")
  end

  # Call the :prompt callback, remember the prompt size,
  # and then feed the prompt to the terminal.
  def draw_prompt
    str = silent_callback(:prompt)
    @prompt_length = str.chars.count # 0 for no prompt, #silent_callback always returns a string
    feed(str)
  end

  # Prints out +text+ on $stdout, but only if the widget
  # is in debug mode.
  def debug(text)
    puts(text) if @debug_terminal
  end

end
