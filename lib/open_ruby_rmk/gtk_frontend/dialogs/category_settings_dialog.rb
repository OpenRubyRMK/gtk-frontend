# -*- coding: utf-8 -*-

# Dialog for adding and adjusting categories and their attribute definitions.
class OpenRubyRMK::GTKFrontend::Dialogs::CategorySettingsDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend
  include OpenRubyRMK::GTKFrontend::Helpers::Icons
  include OpenRubyRMK::GTKFrontend::Helpers::Labels

  # The category edited/created by this dialog.
  attr_reader :category

  # Creates a new instance of this class. +parent_window+ is the
  # window this dialog shall be modal to, +category+ is the
  # category to be edited. If this is nil, a new category
  # is created.
  def initialize(parent_window, category = nil)
    super(t.dialogs.category_settings.name,
          parent_window,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 400, 400

    @category = category || OpenRubyRMK::Backend::Category.new(t.dialogs.category_settings.new_category_name)
    @is_new   = !category
    @accepted = false

    create_widgets
    create_layout
    setup_event_handlers
    fill_in_category_infos
  end

  # Shows all child widgets, then calls the superclass’
  # method. Returns false if the user aborted the dialog,
  # true otherwise.
  def run(*)
    show_all
    super

    @accepted
  end

  # Returns true if the category was created by this window,
  # i.e. if you passed +nil+ to ::new.
  def new_category?
    @is_new
  end

  private

  def create_widgets
    @name_field      = Entry.new
    @attribute_list  = TreeView.new(ListStore.new(String, OpenRubyRMK::Backend::Category::AttributeDefinition)) # Name, full definition instance
    @type_select     = ComboBox.new
    @desc_field      = TextView.new
    @min_field       = Entry.new
    @max_field       = Entry.new
    @min_inf_button  = Button.new("-∞")
    @max_inf_button  = Button.new("∞")
    @choices_entry   = Entry.new
    @list_add_button = Button.new
    @list_del_button = Button.new

    @attribute_list.rules_hint             = true
    @attribute_list.headers_visible        = false
    @attribute_list.selection.mode         = SELECTION_SINGLE
    @attribute_list_name_renderer          = CellRendererText.new
    @attribute_list_name_renderer.editable = true
    @attribute_list.append_column(TreeViewColumn.new("", @attribute_list_name_renderer, text: 0)) # model[0] => Attribute name

    OpenRubyRMK::Backend::Category::ATTRIBUTE_TYPE_CONVERSIONS.keys.sort.each do |sym|
      @type_select.append_text(sym.to_s)
    end
    @type_select.active = 0 # Autoselect the first available option
    @min_field.text = "-∞"
    @max_field.text = "∞"

    @list_add_button.add(icon_image("ui/list-add.png", width: 16))
    @list_del_button.add(icon_image("ui/list-remove.png", width: 16))
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

        left_vbox.pack_start(label(t.dialogs.category_settings.allowed_attributes), false)
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

        right_vbox.pack_start(label(t.dialogs.category_settings.attribute_type), false)
        right_vbox.pack_start(@type_select, false)

        right_vbox.pack_start(label(t.dialogs.category_settings.minimum_and_maximum), false)
        HBox.new.tap do |spin_hbox|
          spin_hbox.spacing = $app.space
          spin_hbox.pack_end(@max_inf_button, false)
          spin_hbox.pack_end(@max_field, true)
          spin_hbox.pack_end(@min_field, true)
          spin_hbox.pack_end(@min_inf_button, false)

          right_vbox.pack_start(spin_hbox, false)
        end

        right_vbox.pack_start(label(t.dialogs.category_settings.choices), false)
        right_vbox.pack_start(@choices_entry, false)

        right_vbox.pack_start(label(t.dialogs.category_settings.choices), false)
        right_vbox.pack_start(@desc_field, true)

        hbox.pack_start(right_vbox)
      end

      vbox.pack_start(hbox, true)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @attribute_list.signal_connect(:cursor_changed, &method(:on_list_cursor_changed))
    @attribute_list_name_renderer.signal_connect(:edited, &method(:on_list_edited))
    @type_select.signal_connect(:changed, &method(:on_type_select_changed))
    @desc_field.buffer.signal_connect(:changed, &method(:on_desc_field_changed))
    @list_add_button.signal_connect(:clicked, &method(:on_list_add_button_clicked))
    @list_del_button.signal_connect(:clicked, &method(:on_list_del_button_clicked))
    @min_field.signal_connect(:changed, &method(:on_minimum_field_changed))
    @max_field.signal_connect(:changed, &method(:on_maximum_field_changed))
    @min_inf_button.signal_connect(:clicked){@min_field.text = "-∞"}
    @max_inf_button.signal_connect(:clicked){@max_field.text = "∞"}
    @choices_entry.signal_connect(:changed, &method(:on_choices_entry_changed))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
      raise(Errors::ValidationError, "No name given") if @name_field.text.empty?
      raise(Errors::ValidationError, "No attributes defined") if @attribute_list.model.iter_first.nil?

      # (Re)set the category’s name
      @category.name = @name_field.text

      # Add new attributes, adjust existing ones
      @attribute_list.model.each do |model, path, iter|
        name, definition = iter[0].to_sym, iter[1] # Come on, nobody exploits a GUI program

        if @category.valid_attribute?(name)
          @category[name].type        = type # FIXME: Convert existing entries?
          @category[name].description = definition.description
          @category[name].minimum = definition.minimum
          @category[name].maximum = definition.maximum
          @category[name].choices = definition.choices
        else
          @category.define_attribute(name, definition)
        end
      end

      # Remove attributes not in the list anymore
      @category.attribute_names.each do |name|
        unless @attribute_list.model.find{|model, path, iter| iter[0].to_sym == name} # to_sym as above
          @category.remove_attribute(name)
        end
      end

      # Finally, if we created a new category, let the project know
      # about it.
      $app.project.add_category(@category) if new_category?

      @accepted = true # Return value of #run, see above
    end

    destroy
  rescue Errors::ValidationError => e
    $app.msgbox(e.message,
                parent: self,
                type: :warning,
                buttons: :close)
  end

  # The user double-clicked on a list item.
  def on_list_edited(cell, path, value)
    @attribute_list.model.get_iter(path)[0] = value
  end

  # The user selected another attribute.
  def on_list_cursor_changed(*args)
    # FIXME: ruby-gtk2 can’t store Symbols in models it seems.
    # If this is deemed a bug (I’ve asked on the ML) and fixed,
    # remove the to_sym below. Otherwise, write the code differently.
    # @type_select.active     = OpenRubyRMK::Backend::Category::ATTRIBUTE_TYPE_CONVERSIONS.keys.sort.index(current_list_iter[1].to_sym) || 0
    # @desc_field.buffer.text = current_list_iter[2]
    @type_select.active     = OpenRubyRMK::Backend::Category::ATTRIBUTE_TYPE_CONVERSIONS.keys.sort.index(current_list_iter[1].type)
    @desc_field.buffer.text = current_list_iter[1].description
    @min_field.text         = current_list_iter[1].minimum == -Float::INFINITY ? "-∞" : current_list_iter[1].minimum.to_s
    @max_field.text         = current_list_iter[1].maximum == Float::INFINITY ? "∞" : current_list_iter[1].maximum.to_s
    @choices_entry.text     = current_list_iter[1].choices.map(&:to_s).join(", ")
  end

  # The user edited the description field.
  def on_desc_field_changed(*)
    return unless current_list_iter

    current_list_iter[1].description = @desc_field.buffer.text
  end

  def on_minimum_field_changed(*)
    return unless current_list_iter

    current_list_iter[1].minimum = @min_field.text == "-∞" ? -Float::INFINITY : @min_field.text.to_f
  end

  def on_maximum_field_changed(*)
    return unless current_list_iter

    current_list_iter[1].maximum = @max_field.text == "∞" ? Float::INFINITY : @max_field.text.to_f
  end

  def on_choices_entry_changed(*)
    return unless current_list_iter

    # FIXME: This generates a whole lot of symbols, one for each letter typed in
    current_list_iter[1].choices = @choices_entry.text.split(/,\s?/).map(&:to_sym)
  end

  # The user edited the type combo box.
  def on_type_select_changed(*)
    return unless current_list_iter
    return if @type_select.active_text.empty?

    current_list_iter[1].type = @type_select.active_text.to_sym # Only a limited number of choices, hence to_sym is safe
  end

  # The user clicked the add button below the attribute list.
  def on_list_add_button_clicked(*)
    row = @attribute_list.model.append
    row[0] = "NewAttribute"
    row[1] = OpenRubyRMK::Backend::Category::AttributeDefinition.new(OpenRubyRMK::Backend::Category::ATTRIBUTE_TYPE_CONVERSIONS.keys.sort.first)
  end

  # The user clicked the deletion button below the attribute list.
  def on_list_del_button_clicked(*)
    return unless current_list_iter

    @attribute_list.model.remove(current_list_iter)
  end

  ########################################
  # Helpers

  # Returns the Gtk::TreeIter for the currently selected item.
  # Returns nil if no item is currently selected.
  def current_list_iter
    return nil unless @attribute_list.cursor[0]
    @attribute_list.model.get_iter(@attribute_list.cursor[0])
  end

  def fill_in_category_infos
    # The category name field
    @name_field.text = @category.name

    # The already existing attribute definitions
    @category.each_allowed_attribute do |name, definition|
      row = @attribute_list.model.append

      # Note the dupping so we don’t accidentally change something
      # in the project although the user after having done some edits
      # clicks “abort”.
      row[0] = name.to_s
      row[1] = definition.dup
    end
  end

end
