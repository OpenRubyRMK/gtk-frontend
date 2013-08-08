# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::TemplatesDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

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
    @codepages = Notebook.new
    @add_template_button = Button.new
    @del_template_button = Button.new

    @list.rules_hint = true
    @list.headers_visible = false
    @list.selection.mode = SELECTION_SINGLE
    @listrenderer = CellRendererText.new
    @listrenderer.editable = true
    @list.append_column(TreeViewColumn.new("", @listrenderer, text: 0))

    @add_template_button.add(icon_image("ui/list-add.png", width: 16))
    @del_template_button.add(icon_image("ui/list-remove.png", width: 16))

    @sourceviews = []
    @paraviews = []
  end

  def create_layout
    HBox.new.tap do |hbox|
      hbox.spacing = $app.space

      VBox.new.tap do |vbox2|
        vbox2.pack_start(@list, true, true)

        HBox.new.tap do |hbox2|
          hbox2.pack_start(@add_template_button, false, false)
          hbox2.pack_end(@del_template_button, false, false)

          vbox2.pack_start(hbox2, false, false)
        end

        hbox.pack_start(vbox2, false, false)
      end

      hbox.pack_start(@codepages, true, true)

      vbox.pack_start(hbox, true, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
    @add_template_button.signal_connect(:clicked, &method(:on_add_template_button_clicked))
    @del_template_button.signal_connect(:clicked, &method(:on_del_template_button_clicked))
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
      # Make the widgets
      sourceview = OpenRubyRMK::GTKFrontend::Widgets::RubySourceView.new
      paraview   = TreeView.new(ListStore.new(String, String, OpenRubyRMK::Backend::Template::Parameter))

      # Tell the parameter list what to display
      paraview.append_column(TreeViewColumn.new("Name", CellRendererText.new, text: 0))
      paraview.append_column(TreeViewColumn.new("Default value", CellRendererText.new, text: 1))

      # Fill in parameters and code for this template page
      sourceview.buffer.text = page.code
      page.parameters.each do |param|
        row = paraview.model.append
        row[0] = param.name
        row[1] = param.required? ? "(required)" : param.default_value
        row[2] = param
      end

      # Add the widgets to the notebook page
      VBox.new.tap do |vbox2|
        scroller1 = ScrolledWindow.new
        scroller2 = ScrolledWindow.new
        scroller1.add(paraview)
        scroller2.add(sourceview)
        vbox2.pack_start(scroller1, false)
        vbox2.pack_start(scroller2, true, true)

        @codepages.append_page(vbox2,
                               Label.new(sprintf(t.dialogs.template_event.labels.page,
                                                 :num => page.number)))
      end
    end
    @codepages.show_all
  end

  def on_add_template_button_clicked(*)
    
  end

  def on_del_template_button_clicked(*)

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
