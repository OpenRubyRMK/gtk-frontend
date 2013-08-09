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
    @add_page_button     = Button.new
    @del_page_button     = Button.new

    @list.rules_hint = true
    @list.headers_visible = false
    @list.selection.mode = SELECTION_SINGLE
    @list.append_column(TreeViewColumn.new("", CellRendererText.new, text: 0))

    @add_template_button.add(icon_image("ui/list-add.png", width: 16))
    @del_template_button.add(icon_image("ui/list-remove.png", width: 16))
    @add_page_button.add(icon_image("ui/list-add.png", width: 16))
    @del_page_button.add(icon_image("ui/list-remove.png", width: 16))

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

      VBox.new.tap do |vbox2|
        vbox2.pack_start(@codepages, true, true)
        HBox.new.tap do |hbox2|
          hbox2.pack_start(@add_page_button, false, false)
          hbox2.pack_start(@del_page_button, false, false, $app.space)

          vbox2.pack_start(hbox2, false, false)
        end

        hbox.pack_start(vbox2, true, true)
      end

      vbox.pack_start(hbox, true, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
    @add_template_button.signal_connect(:clicked, &method(:on_add_template_button_clicked))
    @del_template_button.signal_connect(:clicked, &method(:on_del_template_button_clicked))
    @add_page_button.signal_connect(:clicked, &method(:on_add_page_button_clicked))
    @del_page_button.signal_connect(:clicked, &method(:on_del_page_button_clicked))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    destroy
  end

  def on_list_cursor_changed(*)
    # Clear the notebook for the new template’s pages
    @codepages.n_pages.times{@codepages.remove_page(-1)}

    return unless current_template_list_iter[1]

    template = current_template_list_iter[1]
    template.pages.each do |page|
      insert_page(template, page)
    end
    @codepages.show_all
  end

  def on_add_template_button_clicked(*)
    t = OpenRubyRMK::Backend::Template.new("newparameter")
    $app.project.add_template(t)
    append_template(t)
  end

  def on_del_template_button_clicked(*)
    iter = current_template_list_iter
    return unless iter

    $app.project.remove_template(iter[1])
    @list.model.remove(iter)
  end

  def on_add_page_button_clicked(*)
    return unless iter = current_template_list_iter # Single = intended

    page = OpenRubyRMK::Backend::Template::TemplatePage.new(0)
    page.instance_eval do
      parameter "myparameter"
      code('puts "Hello World!"')
    end

    iter[1].insert_page(@codepages.page + 1, page)

    insert_page(iter[1], page, page.number)
    @codepages.show_all
  end

  def on_del_page_button_clicked(*)
    return unless iter = current_template_list_iter # Single = intended

    iter[1].pages.delete_at(@codepages.page)
    @codepages.remove_page(@codepages.page)
  end

  ########################################
  # Helpers

  def append_template(template)
    row = @list.model.append
    tname = template.name

    row[0] = tname
    row[1] = template
  end

  def insert_page(template, page, index = -1)
    # Make the widgets
    sourceview = OpenRubyRMK::GTKFrontend::Widgets::RubySourceView.new
    paraview   = TreeView.new(ListStore.new(String, String, OpenRubyRMK::Backend::Template::Parameter))
    add_param_button = Button.new
    del_param_button = Button.new

    # Images for the param buttons
    add_param_button.add(icon_image("ui/list-add.png", width: 16))
    del_param_button.add(icon_image("ui/list-remove.png", width: 16))

    # Event handling for the param buttons
    add_param_button.signal_connect(:clicked) do
      param = OpenRubyRMK::Backend::Template::Parameter.new("myparameter", true)
      page.insert_parameter(param, page.parameters.count)
      row = paraview.model.append
      row[0] = param.name
      row[1] = "(required)"
      row[2] = param
    end
    del_param_button.signal_connect(:clicked) do
      if paraview.cursor[0]
        iter = paraview.model.get_iter(paraview.cursor[0])
        page.delete_parameter(iter[2])
        paraview.model.remove(iter)
      end
    end

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
      vbox2.pack_start(scroller1, false, false)

      HBox.new.tap do |hbox2|
        hbox2.pack_start(add_param_button, false, false, $app.space)
        hbox2.pack_start(del_param_button, false, false)

        vbox2.pack_start(hbox2, false, false, $app.space)
      end

      vbox2.pack_start(scroller2, true, true, $app.space)

      @codepages.insert_page(index, vbox2,
                             Label.new(sprintf(t.dialogs.template_event.labels.page,
                                               :num => page.number)))
    end
  end

  def current_template_list_iter
    return nil unless @list.cursor[0]
    @list.model.get_iter(@list.cursor[0])
  end

end
