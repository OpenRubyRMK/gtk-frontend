# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Widgets::TemplatePageParameter < Gtk::VBox
  include R18n::Helpers

  # Marker used when there’s no default value
  # (default may be +nil+, so we can’t use that).
  NO_DEFAULT_VALUE = Object.new


  # The widget actually allowing the user to input something.
  attr_reader :widget
  # The Gtk::Label widget used for the labelling.
  attr_reader :label

  # Create a new instance containing the given +label+
  # (a string) and a Gtk::Entry).
  # If +default+ is supplied, a default value will be
  # inserted on creation via #apply_default, otherwise
  # it isn’t. +default+ may also be +nil+.
  def initialize(label, default = NO_DEFAULT_VALUE)
    super()

    @widget = Gtk::Entry.new
    @default = default
    @label  = Gtk::Label.new(sprintf(t.dialogs.template_event.labels.parameter,
                                     :name => label))

    self.spacing = $app.space
    pack_start(@label, false, false)
    pack_start(@widget, false, false)
    @label.xalign = 0

    apply_default unless no_default?
  end

  # true if no default value has been supplied
  # (= parameter is required), false otherwise.
  def no_default?
    @default == NO_DEFAULT_VALUE
  end

  # The default value. If set to NO_DEFAULT_VALUE,
  # this parameter is required.
  def default
    @default
  end

  # The default value. If set to NO_DEFAULT_VALUE,
  # this parameter is required. Calls #apply_default
  # after @default has been set.
  def default=(val)
    @default = val
    apply_default unless no_default?
  end

  # Override in a subclass. Return the value for
  # the parameter the user entered.
  def value
    @widget.text
  end

  private

  # Override in a subclass. Fill the #widget with
  # what you find in #default.
  def apply_default
    @widget.text = @default.to_s
  end

end
