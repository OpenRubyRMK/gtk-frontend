# -*- coding: utf-8 -*-
require "pathname"
require "yaml"
require "gtk2"

module OpenRubyRMK

  module GTKFrontend

    # This library’s root directory.
    ROOT_DIR = Pathname.new(__FILE__).dirname.parent.parent
    # Path to the VERSION file.
    VERSION_FILE = ROOT_DIR + "VERSION"
    # Path to the AUTHORS file.
    AUTHORS_FILE = ROOT_DIR + "AUTHORS"
    # Path to the COPYING file.
    LICENSE_FILE = ROOT_DIR + "COPYING"

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

  end

end

require_relative "gtk_frontend/app"
require_relative "gtk_frontend/menu_builder"
require_relative "gtk_frontend/main_window"
