class OpenRubyRMK::GTKFrontend::Dialogs::TemplateEventDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize(tmx_object)
    @map_object = OpenRubyRMK::Backend::MapObject.from_tmx_object(tmx_object)
    @template   = $app.project.templates.find{|template| template.name == @map_object.type}

    unless @template
      raise(OpenRubyRMK::GTKFrontend::Errors::UnknownTemplate.new(@map_object.type))
    end

    tname = t["templates"][@template.name] | @template.name.capitalize # Single | intended, this is a feature of R18n
    super(sprintf(t.dialogs.template_event.title, :tname => tname),
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
    @sourcecode_fields = @template.pages.map{|page| TextView.new}
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      # Top widgets for name and ID
      hbox.pack_start(Label.new("Name:"), false, false)
      hbox.pack_start(@name_field, false, false, $app.space)
      hbox.pack_start(Label.new("ID: #{@map_object.formatted_id}"), false, false)
      vbox.pack_start(hbox, false, false)

      # The pages
      Notebook.new.tap do |nbook|
        build_pages(nbook)
        vbox.pack_start(nbook, true, true)
      end

    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  def on_response(_, res)
    # TODO: Something useful?
    destroy
  end

  # Fill the Gtk::Notebook +nbook+ with pages for the
  # template pages found in @template.
  def build_pages(nbook)
    @template.pages.each_with_index do |page, index|
      VBox.new.tap do |pagevbox|
        sw = ScrolledWindow.new
        sw.add(@sourcecode_fields[index])
        pagevbox.pack_start(sw, true, true)

        nbook.append_page(pagevbox,
                          Label.new(sprintf(t.dialogs.template_event.labels.page,
                                            :num => page.number)))
      end
    end
  end

end
