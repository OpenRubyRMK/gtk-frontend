# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Dialogs::CategorySettingsDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons
  include OpenRubyRMK::GTKFrontend::Helpers::Labels

  def initialize(parent_window, category = nil)
    super("Category settings",
          parent_window,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 400, 300

    @is_new   = !category
    @category = category || OpenRubyRMK::Backend::Category.new("stuff")

    create_widgets
    create_layout
    setup_event_handlers
  end

  # Checks if the category being edited was also created
  # by this dialog. This will be the case if you passed
  # +nil+ as the first parameter to ::new.
  def new_category?
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
    @name_field      = Entry.new
    @attribute_list  = Widgets::ListView.new(true)
    @type_select     = ComboBox.new
    @desc_field      = TextView.new
    @list_add_button = Button.new
    @list_del_button = Button.new

    OpenRubyRMK::Backend::Category::ATTRIBUTE_TYPE_CONVERSIONS.keys.sort.each do |sym|
      @type_select.append_text(sym.to_s)
    end

    @list_add_button.add(icon_image("ui/list-add.svg", width: 16))
    @list_del_button.add(icon_image("ui/list-remove.svg", width: 16))

    @attribute_list.edit_cell do
      puts "Editing!"
    end
  end

  def create_layout
    vbox.spacing = $app.space

    vbox.pack_start(label("Name:"), false)
    vbox.pack_start(@name_field, false)

    HBox.new.tap do |hbox|
      hbox.spacing = $app.space

      # Left side
      VBox.new.tap do |left_vbox|
        left_vbox.spacing = $app.space

        left_vbox.pack_start(label("Allowed atttributes:"), false)
        left_vbox.pack_start(@attribute_list, true)

        HBox.new.tap do |list_button_hbox|
          list_button_hbox.spacing = $app.space
          list_button_hbox.pack_end(@list_add_button, false)
          list_button_hbox.pack_end(@list_del_button, false)

          left_vbox.pack_start(list_button_hbox, false)
        end

        hbox.pack_start(left_vbox, true)
      end

      # Right side
      VBox.new.tap do |right_vbox|
        right_vbox.spacing = $app.space

        right_vbox.pack_start(label("Attribute type:"), false)
        right_vbox.pack_start(@type_select, false)
        right_vbox.pack_start(label("Attribute description"), false)
        right_vbox.pack_start(@desc_field, true)

        hbox.pack_start(right_vbox)
      end

      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    # TODO: Modify the category!
    destroy
  end

end
