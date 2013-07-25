# -*- coding: utf-8 -*-
require "pathname"
require "yaml"
require "gtk2"
require "vte"
require "r18n-desktop"
require "ripl"
require "ripl/multi_line"
require "paint"
require "open_ruby_rmk/backend"

# Namespace of the OpenRubyRMK project.
module OpenRubyRMK

  # Namespace containing everything related to the GTK
  # frontend.
  module GTKFrontend

    # This library’s root directory.
    ROOT_DIR = Pathname.new(__FILE__).dirname.parent.parent
    # Path to the VERSION file.
    VERSION_FILE = ROOT_DIR + "VERSION"
    # Path to the AUTHORS file.
    AUTHORS_FILE = ROOT_DIR + "AUTHORS"
    # Path to the COPYING file.
    LICENSE_FILE = ROOT_DIR + "COPYING"
    # Directory containing non-code info.
    DATA_DIR = ROOT_DIR + "data"
    # The directory containing the locale files.
    LOCALE_DIR = DATA_DIR + "locales"
    # The path to the global configuration file.
    GLOBAL_CONFIG_FILE = DATA_DIR + "config.yml"
    # The directory where GUI icons are kept.
    ICONS_DIR = DATA_DIR + "icons"
    # The path to the user-specific configuration file.
    USER_CONFIG_FILE = Pathname.new(GLib.filename_to_utf8(GLib.user_config_dir)) + "openrubyrmk" + "config-gtk.yml"
    # The path to the user-specific cache directory.
    USER_CACHE_DIR   = Pathname.new(GLib.filename_to_utf8(GLib.user_cache_dir)) + "openrubyrmk" + "gtk-frontend"

    # The version of this software.
    def self.version
      VERSION_FILE.read.chomp
    end

    # Author information; a hash of the following form:
    #   {"programmers" => {"name" => "email"},
    #    "artists",    => {"name" => "email"},
    #    "documenters" => {"name" => "email"},
    #    "translators" => {"name" => "email"}}
    def self.authors
      YAML.load_file(AUTHORS_FILE.to_s)
    end

    # The complete license text.
    def self.license
      LICENSE_FILE.read
    end

    # The contents of the configuration files as a hash, where
    # the global configuration file is loaded first, followed by
    # the per-user configuration file (which overwrites any
    # values from the global configuration file where requested).
    # The hash’s content is merely unparsed, so use App#config
    # to get a more meaningful value.
    def self.bare_config
      # If the user doesn’t have a config file yet, create one
      unless USER_CONFIG_FILE.file?
        USER_CONFIG_FILE.parent.mkpath unless USER_CONFIG_FILE.parent.directory?

        USER_CONFIG_FILE.open("w") do |file|
          file.puts("# User configuration file for the OpenRubyRMK")
          file.puts("#")
          file.puts("# Place your user-specific configuration options here.")
          file.puts("# The format is the same as for the global config file.")
        end
      end

      # Load the config, where the user config overrides values
      # in the global config.
      hsh = YAML.load_file(GLOBAL_CONFIG_FILE.to_s)
      hsh.merge(YAML.load_file(USER_CONFIG_FILE.to_s) || {}) # Returns `false' for an empty file
    end

    ########################################
    # Other namespace definitions

    # Namespace containing helpers for GUI layout.
    module Helpers
    end

    # Namespace containing additional widgets.
    module Widgets
    end

    # Namespace containing floating tool windows.
    module ToolWindows
    end

    # Namespace containing (modal) dialog windows.
    module Dialogs
    end

  end

end

########################################
# Monkey patches

class R18n::TranslatedString
  def to_label
    Gtk::Label.new(self.to_s)
  end
end

class Gtk::ListStore
  include Enumerable # They have #each, why not Enumerable?
end

require_relative "gtk_frontend/errors"
require_relative "gtk_frontend/validatable"
require_relative "gtk_frontend/licenser"
require_relative "gtk_frontend/evented_storage"
require_relative "gtk_frontend/helpers/gtk_helper"
require_relative "gtk_frontend/helpers/labels"
require_relative "gtk_frontend/helpers/icons"
require_relative "gtk_frontend/widgets/image_grid"
require_relative "gtk_frontend/widgets/map_grid"
require_relative "gtk_frontend/widgets/map_tree_view"
require_relative "gtk_frontend/widgets/directory_tree_view"
require_relative "gtk_frontend/widgets/list_view"
require_relative "gtk_frontend/widgets/image_link_button"
require_relative "gtk_frontend/widgets/ruby_terminal"
require_relative "gtk_frontend/widgets/recent_open"
require_relative "gtk_frontend/widgets/tileset_book"
require_relative "gtk_frontend/widgets/template_combobox"
require_relative "gtk_frontend/tool_windows/map_window"
require_relative "gtk_frontend/tool_windows/tileset_window"
require_relative "gtk_frontend/tool_windows/layer_window"
require_relative "gtk_frontend/tool_windows/console_window"
require_relative "gtk_frontend/dialogs/map_settings_dialog"
require_relative "gtk_frontend/dialogs/resource_selection_dialog"
require_relative "gtk_frontend/dialogs/add_tileset_dialog"
require_relative "gtk_frontend/dialogs/resource_dialog"
require_relative "gtk_frontend/dialogs/resource_preview_dialog"
require_relative "gtk_frontend/dialogs/settings_dialog"
require_relative "gtk_frontend/dialogs/categories_dialog"
require_relative "gtk_frontend/dialogs/category_settings_dialog"
require_relative "gtk_frontend/dialogs/text_dialog"
require_relative "gtk_frontend/dialogs/choice_dialog"
require_relative "gtk_frontend/main_window"
require_relative "gtk_frontend/app"
