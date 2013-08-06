class OpenRubyRMK::GTKFrontend::Dialogs::EventDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize(tmx_object)
    @map_object = OpenRubyRMK::Backend::MapObject.from_tmx_object(tmx_object)

    super("Edit generic event",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 500, 500
    create_widgets
    create_layout
    setup_event_handlers
  end

  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @name_field = Entry.new
    @name_field.text = @map_object.custom_name
  end

  def create_layout
    vbox.spacing = $app.space

    # Top widgets for name and ID
    HBox.new.tap do |hbox|
      hbox.pack_start(@name_field, false, false, $app.space)
      hbox.pack_start(Label.new("ID: #{@map_object.formatted_id}"), false, false)

      vbox.pack_start(hbox, false, false)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
    else
    end

    destroy
  end

end
