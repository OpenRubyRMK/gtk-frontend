# -*- coding: utf-8 -*-
class OpenRubyRMK::GTKFrontend::Dialogs::CategoriesDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  # The attribute values’ table’s number of rows.
  TABLE_ROWS    = 5
  # The attribute values’ table’s number of columns.
  TABLE_COLUMNS = 5

  def initialize
    super(t.dialogs.categories.name,
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::CLOSE, Dialog::RESPONSE_ACCEPT])

    set_default_size 300, 300

    create_widgets
    create_layout
    setup_event_handlers

    $app.project.categories.each do |cat|
      append_category(cat)
    end
  end

  # Shows all child widgets, then calls the superclass’
  # method.
  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @notebook   = Notebook.new
    @add_button = Button.new
    @del_button = Button.new

    @add_button.add(icon_image("ui/list-add.svg", width: 16))
    @del_button.add(icon_image("ui/list-remove.svg", width: 16))
  end

  def create_layout
    vbox.spacing = $app.space

    HBox.new.tap do |hbox|
      hbox.pack_end(@del_button, false)
      hbox.pack_end(@add_button, false)

      hbox.border_width = $app.space
      vbox.pack_start(hbox, false)
    end

    vbox.pack_start(@notebook)
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @add_button.signal_connect(:clicked, &method(:on_add_button_clicked))
    @del_button.signal_connect(:clicked, &method(:on_del_button_clicked))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    destroy
  end

  def on_add_button_clicked(*)
    cd = Dialogs::CategorySettingsDialog.new(self)
    cd.run
  end

  def on_del_button_clicked(*)
    raise(NotImplementedError, "Someone needs to implement deletion of categories")
  end

  ########################################
  # Helpers

  def append_category(cat)
    HBox.new.tap do |hbox|
      hbox.spacing      = $app.space
      hbox.border_width = $app.space

      hbox.pack_start(create_entry_list(cat), true, true)
      hbox.pack_start(create_attribute_widgets(cat), true, true)

      @notebook.append_page(hbox, Label.new(cat.name))
    end
  end

  # Creates the ListView for the list of entry names
  def create_entry_list(cat)
    entry_list                        = TreeView.new(ListStore.new(String, OpenRubyRMK::Backend::Category::Entry)) # Name, Entry instance
    entry_list.rules_hint             = true
    entry_list.headers_visible        = false
    entry_list.selection.mode         = SELECTION_SINGLE
    entry_list_name_renderer          = CellRendererText.new
    entry_list_name_renderer.editable = true
    entry_list.append_column(TreeViewColumn.new("", entry_list_name_renderer, text: 0)) # model[0] => entry name
    entry_list.set_size_request(200, 200)

    cat.each do |entry|
      row = entry_list.model.append
      row[0] = entry[:name] # We require a :name attribute to be defined!
      row[1] = entry
    end

    Frame.new.tap{|frame| frame.add(entry_list)}
  end

  # Creates the table of widgets for entering the attribute
  # values for an entry.
  def create_attribute_widgets(cat)
    Table.new(TABLE_ROWS, TABLE_COLUMNS, true).tap do |table|
      table.column_spacings = $app.space
      table.row_spacings    = $app.space
      row, col              = 0, 0

      cat.each do |entry|
        cat.each_allowed_attribute do |sym, definition|
          label = Label.new("#{sym.to_s.capitalize}:")
          label.xalign = 0

          widget = case definition.type
                   when :number then Entry.new
                   when :float  then Entry.new
                   when :ident  then Entry.new
                   when :string then Entry.new
                   end

          box = VBox.new
          box.pack_start(label, false, false)
          box.pack_start(widget, true, true)

          table.attach_defaults(box, row, row + 1, col, col + 1)
          col += 1

          if col >= TABLE_COLUMNS
            col = 0
            row += 1
          end
        end
      end
    end
  end

end
