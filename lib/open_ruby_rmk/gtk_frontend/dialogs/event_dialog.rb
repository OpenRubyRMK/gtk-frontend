class OpenRubyRMK::GTKFrontend::Dialogs::EventDialog < Gtk::Dialog
  include Gtk
  include R18n::Helpers
  include OpenRubyRMK::GTKFrontend::Helpers::Icons

  def initialize(tmx_object)
    @map_object = OpenRubyRMK::Backend::MapObject.from_tmx_object(tmx_object)

    super("Edit generic event",
          $app.mainwindow,
          Dialog::MODAL | Dialog::DESTROY_WITH_PARENT,
          [Stock::OK, Dialog::RESPONSE_ACCEPT],
          [Stock::CANCEL, Dialog::RESPONSE_REJECT])

    set_default_size 700, 500
    create_widgets
    create_layout
    setup_event_handlers

    @map_object.pages.each{|page| add_page(page)}
  end

  def run(*)
    show_all
    super
  end

  private

  def create_widgets
    @name_field = Entry.new
    @name_field.text = @map_object.custom_name
    @notebook = Notebook.new
    @page_widgets = []
    @add_page_button = Button.new
    @del_page_button = Button.new

    @add_page_button.add(icon_image("ui/list-add.png", width: 16))
    @del_page_button.add(icon_image("ui/list-remove.png", width: 16))
  end

  def create_layout
    vbox.spacing = $app.space

    # Top widgets for name and ID
    HBox.new.tap do |hbox|
      hbox.pack_start(@name_field, false, false, $app.space)
      hbox.pack_start(Label.new("ID: #{@map_object.formatted_id}"), false, false)

      vbox.pack_start(hbox, false, false)
    end

    vbox.pack_start(@notebook, true, true)
    HBox.new.tap do |hbox|
      hbox.pack_start(@add_page_button, false, false)
      hbox.pack_start(@del_page_button, false, false, $app.space)

      vbox.pack_start(hbox, false, false)
    end
  end

  def setup_event_handlers
    signal_connect(:response, &method(:on_response))
    @add_page_button.signal_connect(:clicked, &method(:on_add_page_button_click))
    @del_page_button.signal_connect(:clicked, &method(:on_del_page_button_click))
  end

  ########################################
  # Event handlers

  def on_response(_, res)
    if res == Gtk::Dialog::RESPONSE_ACCEPT
    else
    end

    destroy
  end

  def on_add_page_button_click(*)
    page = OpenRubyRMK::Backend::MapObject::Page.new
    @map_object.add_page(page)
    add_page(page, @map_object.pages.count - 1)
  end

  def on_del_page_button_click(*)
    @map_object.delete_page(@map_object.pages.count - 1)
    @notebook.remove_page(-1)
  end


  ########################################
  # Helpers

  def add_page(page, pagenum)
    HBox.new.tap do |hbox|
      hbox.spacing = $app.space
      hsh = {}

      #################### Left side ####################
      HBox.new.tap do |left_hbox|
        VBox.new.tap do |left_vbox|
          HBox.new.tap do |hbox1|

            Frame.new("Graphic").tap do |frame|
              VBox.new.tap do |graphicvbox|
                graphicvbox.spacing = $app.space

                imgbutton = Button.new
                imgbutton.add(Image.new(page.graphic.to_s)) if page.graphic.exist?
                imgbutton.set_size_request(96, 96)
                hsh[:imgbutton] = imgbutton

                graphicvbox.pack_start(imgbutton, true, true, $app.space)
                frame.add(graphicvbox)
              end

              hbox1.pack_start(frame, false, false, $app.space)
            end

            Frame.new("Trigger").tap do |frame|
              VBox.new.tap do |triggervbox|
                triggervbox.spacing = $app.space

                ary = []
                ary << RadioButton.new("Activate")
                ary << RadioButton.new(ary.first, "Immediate")
                ary << RadioButton.new(ary.first, "None")

                case page.trigger
                when :activate  then ary[0].active = true
                when :immediate then ary[1].active = true
                when :none      then ary[2].active = true
                else
                  warn("Unknown trigger: #{page.trigger.inspect}")
                end

                ary.each{|rb| triggervbox.pack_start(rb, false, false)}
                hsh[:trigger_buttons] = ary

                frame.add(triggervbox)
              end

              hbox1.pack_start(frame, true, true)
            end

            left_vbox.pack_start(hbox1, true, true)
          end

          # TODO: Add some useful widgets instead of this frame
          # that currently acts just as a placeholder.
          Frame.new("Stuff").tap do |frame|
            left_vbox.pack_start(frame, true, true)
          end

          left_hbox.pack_start(left_vbox, true, true)
        end

        hbox.pack_start(left_hbox, false, false)
      end

      hbox.pack_start(VSeparator.new, false, false)

      #################### Right side ######################
      sourceview = OpenRubyRMK::GTKFrontend::Widgets::RubySourceView.new
      sourceview.buffer.text = page.code
      scroller = ScrolledWindow.new.tap{|sw| sw.add(sourceview)}
      hbox.pack_start(scroller, true, true)
      hsh[:sourceview] = sourceview

      #################### Finalising ####################
      @page_widgets << hsh
      hbox.show_all
      @notebook.append_page(hbox, Label.new(sprintf(t.dialogs.event.labels.page, :num => pagenum)))
    end
  end

end
