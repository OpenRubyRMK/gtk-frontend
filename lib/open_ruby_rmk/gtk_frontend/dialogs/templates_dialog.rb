# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::TemplatesDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers

  def initialize
    super("Templates",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_ACCEPT])

    set_default_size 700, 400

    create_widgets
    create_layout
    setup_event_handlers

    $app.project.templates.each do |template|
      append_template(template)
    end
  end

  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @list = TreeView.new(ListStore.new(String, OpenRubyRMK::Backend::Template))

    @list.rules_hint = true
    @list.headers_visible = false
    @list.selection.mode = SELECTION_SINGLE
    @listrenderer = CellRendererText.new
    @listrenderer.editable = true
    @list.append_column(TreeViewColumn.new("", @listrenderer, text: 0))

    @codepages = Notebook.new
  end

  def create_layout
    HBox.new.tap do |hbox|
      hbox.pack_start(@list, false, false)
      hbox.pack_start(@codepages, true, true)

      vbox.pack_start(hbox, true, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    destroy
  end

  def on_list_cursor_changed(*)
    # Clear the notebook for the new template’s pages
    @codepages.n_pages.times{@codepages.remove_page(-1)}

    return unless current_list_iter[1]

    template = current_list_iter[1]
    template.pages.each do |page|
      sourceview = OpenRubyRMK::GTKFrontend::Widgets::RubySourceView.new
      sourceview.buffer.text = page.code

      @codepages.append_page(sourceview,
                             Label.new(sprintf(t.dialogs.template_event.labels.page,
                                               :num => page.number)))
    end
    @codepages.show_all
  end

  ########################################
  # Helpers

  def append_template(template)
    row = @list.model.append
    tname = template.name

    row[0] = tname
    row[1] = template
  end

  def current_list_iter
    return nil unless @list.cursor[0]
    @list.model.get_iter(@list.cursor[0])
  end

end
