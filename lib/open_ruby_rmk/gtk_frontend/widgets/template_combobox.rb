# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Widgets::TemplateCombobox < Gtk::ComboBox
  include Gtk
  include R18n::Helpers

  def initialize
    model = ListStore.new(String, String, OpenRubyRMK::Backend::Template) # identifier, name, template
    super(model)

    renderer = CellRendererText.new
    pack_start(renderer, true)
    set_attributes(renderer, :text => 1)

    $app.project.templates.each{|template| add_template(template)} if $app.project
    $app.observe(:project_changed) do |event, sender, info|
      model.clear


      if info[:project]
        info[:project].templates.each{|template| add_template(template)}

        info[:project].observe(:template_added) do |event, sender, info2|
          add_template(info2[:template])
        end

        info[:project].observe(:template_removed) do |event, sender, info2|
          remove_template(info2[:template])
        end

      end
    end
  end

  def add_template(template)
    iter = model.append
    iter[0] = template.name
    iter[1] = t["templates"][template.name] | template.name.capitalize # Single | intended, this is a feature of R18n
    iter[2] = template
  end

  def remove_template(template)
    # TODO
    raise(NotImplementedError, "TODO: Can't remove templates yet")
  end

end
