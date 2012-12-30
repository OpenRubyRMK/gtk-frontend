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
    # The path to the configuration file.
    CONFIG_FILE = DATA_DIR + "config.yml"
    # The directory where GUI icons are kept.
    ICONS_DIR = DATA_DIR + "icons"

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

    # The contents of the configuration file as a hash,
    # merely unparsed. Use App#config to get a more meaningful
    # value.
    def self.bare_config
      YAML.load_file(CONFIG_FILE)
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

require_relative "gtk_frontend/errors"
require_relative "gtk_frontend/licenser"
require_relative "gtk_frontend/helpers/gtk_helper"
require_relative "gtk_frontend/helpers/icons"
require_relative "gtk_frontend/widgets/image_grid"
require_relative "gtk_frontend/widgets/map_grid"
require_relative "gtk_frontend/widgets/map_tree_view"
require_relative "gtk_frontend/widgets/directory_tree_view"
require_relative "gtk_frontend/widgets/list_view"
require_relative "gtk_frontend/widgets/image_link_button"
require_relative "gtk_frontend/widgets/ruby_terminal"
require_relative "gtk_frontend/widgets/tileset_book"
require_relative "gtk_frontend/tool_windows/map_window"
require_relative "gtk_frontend/tool_windows/tileset_window"
require_relative "gtk_frontend/tool_windows/console_window"
require_relative "gtk_frontend/dialogs/map_settings_dialog"
require_relative "gtk_frontend/dialogs/resource_dialog"
require_relative "gtk_frontend/dialogs/resource_preview_dialog"
require_relative "gtk_frontend/dialogs/settings_dialog"
require_relative "gtk_frontend/main_window"
require_relative "gtk_frontend/app"
