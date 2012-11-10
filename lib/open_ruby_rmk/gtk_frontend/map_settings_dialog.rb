# -*- coding: utf-8 -*-

# Dialog for creating new and editing existing maps.
class OpenRubyRMK::GTKFrontend::MapSettingsDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend

  # The map this dialog is associated with.
  attr_reader :map

  # Generate a new and unused map ID.
  def self.generate_map_id
    @last_map_id ||= 0
    @last_map_id += 1
  end

  # Create a new dialog window.
  # == Parameters
  # [map (nil)]
  #   The map this window shall edit. If this is +nil+,
  #   a new map will automatically be created. Note
  #   that this object will not be changed in any way
  #   until the user presses the dialog’s OK button;
  #   aborting the dialog will also leave this object
  #   untouched.
  # == Return value
  # The newly created instance.
  def initialize(map = nil)
    super(t.dialogs.map_settings.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 400, 300

    @map = map || OpenRubyRMK::Backend::Map.new(self.class.generate_map_id)

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
    @name_field   = Entry.new
    @width_field  = SpinButton.new(1, 99999, 5) # GTK doesn’t like Float::INFINITY as the max value
    @height_field = SpinButton.new(1, 99999, 5) # GTK doesn’t like Float::INFINITY as the max value

    # Load values from the associated map
    @width_field.value  = @map.tmx_map.width
    @height_field.value = @map.tmx_map.height
    @name_field.text    = @map[:name]
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      hbox.pack_start(Label.new(t.dialogs.map_settings.labels.map_name), false)
      vbox.pack_start(hbox, false)
    end
    vbox.pack_start(@name_field, false)

    HBox.new.tap do |hbox|
      hbox.pack_start(Label.new(t.dialogs.map_settings.labels.width_height), false)
      vbox.pack_start(hbox, false)
    end
    HBox.new.tap do |hbox|
      hbox.pack_start(@width_field)
      hbox.pack_start(Label.new("✕"), false)
      hbox.pack_start(@height_field)
    
      vbox.pack_start(hbox, false)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  # Called when the user wants to exit the dialog.
  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      raise(Errors::ValidationError, t.dialogs.map_settings.errors.map_name_empty) if @name_field.text.empty?

      @map.tmx_map.width  = @width_field.value
      @map.tmx_map.height = @height_field.value
      @map[:name]         = @name_field.text
    end

    destroy
  rescue Errors::ValidationError => e
    $app.msgbox(e.message,
                parent: self,
                type: :warning,
                buttons: :close)
  end

end
