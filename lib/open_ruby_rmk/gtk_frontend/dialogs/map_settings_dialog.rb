# -*- coding: utf-8 -*-

# Dialog for creating new and editing existing maps.
class OpenRubyRMK::GTKFrontend::Dialogs::MapSettingsDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend

  # The map this dialog is associated with.
  attr_reader :map

  # Generate a new and unused map ID.
  def self.generate_map_id
    # If we don’t have a last map ID yet, iterate through
    # all the current project’s maps and find the largest
    # ID in use. From there on we can safely count up.
    unless defined?(@last_map_id)
      @last_map_id = 0

      $app.project.root_maps.each do |root_map|
        root_map.traverse(true) do |map|
          @last_map_id = map.id if map.id > @last_map_id
        end
      end
    end

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
  # [parent (nil)]
  #   If +map+ is +nil+, this will cause a new Backend::Map
  #   instance to be created. You can specify the target
  #   parent for that newly created map by passing it as
  #   a Backend::Map instance for this parameter. If it is
  #   +nil+, a root map will be created. If +map+ isn’t +nil+,
  #   this parameter is ignored (i.e. you can’t do reparenting
  #   this way).
  # == Return value
  # The newly created instance.
  def initialize(map = nil, parent = nil)
    super(t.dialogs.map_settings.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 400, 300

    @is_new     = !map
    @parent     = parent
    @map        = map || OpenRubyRMK::Backend::Map.new(self.class.generate_map_id)

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Checks if the map edited with this dialog was also
  # created by this dialog. This will be the case if you
  # passed +nil+ as the first parameter to ::new.
  def new_map?
    @is_new
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

      @map.parent = @parent if new_map? and @parent

      @map.tmx_map.width  = @width_field.value
      @map.tmx_map.height = @height_field.value
      @map[:name]         = @name_field.text

      # If we created this map and it’s a root map,
      # we need to make the project aware of it.
      $app.project.add_root_map(@map) if new_map? and @map.root?
    end

    destroy
  rescue Errors::ValidationError => e
    $app.msgbox(e.message,
                parent: self,
                type: :warning,
                buttons: :close)
  end

end
