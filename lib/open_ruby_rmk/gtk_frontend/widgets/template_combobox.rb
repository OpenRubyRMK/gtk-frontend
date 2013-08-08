# -*- coding: utf-8 -*-

class OpenRubyRMK::GTKFrontend::Widgets::TemplateCombobox < Gtk::ComboBox
  include Gtk
  include R18n::Helpers

  def initialize
    model = ListStore.new(String, String, OpenRubyRMK::Backend::Template) # identifier, (translated) name, template
    super(model)

    # Tell GTK which column to use for the text
    renderer = CellRendererText.new
    pack_start(renderer, true)
    set_attributes(renderer, :text => 1)

    # Predefine the event handlers, we need them for multiple observations
    template_added   = lambda{|event, sender, info| add_template(info[:template])}
    template_removed = lambda{|event, sender, info| remove_template(info[:template])}

    # Observe the current project for new templates/removal of templates
    # and load the templates already defined at this point (only
    # if there’s a project at all, of course).
    if $app.project
      # The <none> entry
      row = model.append
      row[0] = ""
      row[1] = t.misc.no_template
      row[2] = nil # nil = use generic event

      $app.project.templates.each{|template| add_template(template)}
      $app.project.observe(:template_added, &template_added)
      $app.project.observe(:template_removed, &template_removed)

      self.active_iter = model.iter_first
    end

    # We also want to get notified when the project as such changes.
    $app.observe(:project_changed) do |event, sender, info|
      model.clear # New project, reset templates

      # If there’s a new project, process it the same way we processed
      # the current project above (and here we need the event handlers
      # again)
      if info[:project]
        row = model.append
        row[0] = ""
        row[1] = t.misc.no_template
        row[2] = nil

        info[:project].templates.each{|template| add_template(template)}

        info[:project].observe(:template_added, &template_added)
        info[:project].observe(:template_removed, &template_removed)

        self.active_iter = model.iter_first
      end
    end

    # Set up a signal handler so we can update the global state
    signal_connect(:changed, &method(:on_change))
  end

  def add_template(template)
    iter = model.append

    iter[0] = template.name
    iter[1] = t["templates"][template.name] | template.name.capitalize # Single | intended, this is a feature of R18n
    iter[2] = template
  end

  def remove_template(template)
    iter = model.iter_first
    loop do
      if iter.next!
        break if iter[2] == template
      else
        warn("Did not find template #{template.inspect} in the template combobox, ignoring.")
        return
      end # If we don’t have that iter (whyever), ignore that.
    end

    model.remove(iter)

    self.active_iter = model.iter_first # may be nil if the last template is removed; issues :changed event
  end

  private

  def on_change(*)
    if model.count.zero? # All templates deleted
      $app.state[:core][:template] = nil
    else
      $app.state[:core][:template] = active_iter[2]
    end
  end

end
