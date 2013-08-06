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
    @codeview = SourceView.new

    @list.rules_hint = true
    @list.headers_visible = false
    @list.selection.mode = SELECTION_SINGLE
    @listrenderer = CellRendererText.new
    @listrenderer.editable = true
    @list.append_column(TreeViewColumn.new("", @listrenderer, text: 0))

    @codeview.show_line_numbers = true
    @codeview.insert_spaces_instead_of_tabs = true
    @codeview.indent_width = 2
    @codeview.show_right_margin = true
    @codeview.right_margin_position = 80
    @codeview.buffer.language = SourceLanguageManager.new.get_language("ruby")
    @codeview.buffer.highlight_syntax = true
    @codeview.buffer.highlight_matching_brackets = true
  end

  def create_layout
    HBox.new.tap do |hbox|
      hbox.pack_start(@list, false, false)
      hbox.pack_start(@codeview, true, true)

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
    # TODO: Pages!
    @codeview.buffer.text = current_list_iter[1].pages.first.code
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
