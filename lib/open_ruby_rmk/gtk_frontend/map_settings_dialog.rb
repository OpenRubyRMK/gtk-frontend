# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::MapSettingsDialog < Gtk::Dialog
  include Gtk

  MapSettings = Struct.new(:name, :width, :height)

  attr_reader :map_settings

  # Generate a new and unused map ID.
  def self.generate_map_id
    @last_map_id ||= 0
    @last_map_id += 1
  end

  def initialize(map = nil)
    super("Map settings",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    @map = map
    @map_settings = MapSettings.new

    create_widgets
    setup_event_handlers
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  def new_map?
    @map.nil?
  end

  private

  def create_widgets
    vbox.add(Label.new("Hi there"))
  end

  def setup_event_handlers
    #signal_connect(:response){|x| p("SIG: #{x}"); destroy}
  end

end
