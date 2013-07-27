class OpenRubyRMK::GTKFrontend::Dialogs::TemplateEventDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize(template)
    tname = t["templates"][template.name] | template.name.capitalize # Single | intended, this is a feature of R18n
    super(sprintf(t.dialogs.template_event, :tname => tname),
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    @template = template
    set_default_size 600, 600

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
  end

  def create_layout
  end

  def setup_event_handlers
  end

end
