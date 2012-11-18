# -*- coding: utf-8 -*-

# Worker module used to gather URL and icon information from license
# strings such as "CC-BY-SA", "CC-BY 2.5", "LGPLv2", etc. If you think
# a license is missing, add the appropriate information to the LICENSES
# hash, include an icon in data/icons/licenses if possible, and submit
# a pull request!
module OpenRubyRMK::GTKFrontend::Licenser

  # Filename relative to data/icons/licenses representing the
  # default copyright icon.
  DEFAULT_ICON_NAME = "default.svg"

  # Maps license names to online license URLs and display images.
  # Both the URL and the icon path may be +nil+, but generally you
  # don’t want the URL to be +nil+. If the icon path is +nil+,
  # ::decompose_license will automatically fall back to the
  # value of DEFAULT_ICON_NAME.
  LICENSES = {
    # Creative Commons defaults
    /^CC-BY$/xi       => ["http://creativecommons.org/licenses/by/3.0/", "cc/by.svg"],
    /^CC-BY-SA$/xi    => ["http://creativecommons.org/licenses/by-sa/3.0/", "cc/by-sa.svg"],
    /^CC-BY-ND$/xi    => ["http://creativecommons.org/licenses/by-nd/3.0/", "cc/by-nd.svg"],
    /^CC-BY-NC$/xi    => ["http://creativecommons.org/licenses/by-nc/3.0/", "cc/by-nc.svg"],
    /^CC-BY-NC-SA$/xi => ["http://creativecommons.org/licenses/by-nc-sa/3.0/", "cc/by-nc-sa.svg"],
    /^CC-BY-NC-ND$/xi => ["http://creativecommons.org/licenses/by-nc-nd/3.0/", "cc/by-nc-nd.svg"],
    /^CC-ZERO|CC0$/xi => ["http://creativecommons.org/publicdomain/zero/1.0/", "cc/cc-zero.svg"],

    # Creative Commons 3.0
    /^CC-BY       \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by/3.0/", "cc/by.svg"],
    /^CC-BY-SA    \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by-sa/3.0/", "cc/by-sa.svg"],
    /^CC-BY-ND    \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by-nd/3.0/", "cc/by-nd.svg"],
    /^CC-BY-NC    \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by-nc/3.0/", "cc/by-nc.svg"],
    /^CC-BY-NC-SA \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by-nc-sa/3.0/", "cc/by-nc-sa.svg"],
    /^CC-BY-NC-ND \s+ 3\.0$/xi => ["http://creativecommons.org/licenses/by-nc-nd/3.0/", "cc/by-nc-nd.svg"],

    # Creative Commons 2.5
    /^CC-BY       \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by/2.5/", "cc/by.svg"],
    /^CC-BY-SA    \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by-sa/2.5/", "cc/by-sa.svg"],
    /^CC-BY-ND    \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by-nd/2.5/", "cc/by-nd.svg"],
    /^CC-BY-NC    \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by-nc/2.5/", "cc/by-nc.svg"],
    /^CC-BY-NC-SA \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by-nc-sa/2.5/", "cc/by-nc-sa.svg"],
    /^CC-BY-NC-ND \s+ 2\.5$/xi => ["http://creativecommons.org/licenses/by-nc-nd/2.5/", "cc/by-nc-nd.svg"],

    # GNU license defaults
    /^GPL$/xi => ["http://www.gnu.org/licenses/gpl-3.0", "gnu/gpl-v3-logo.svg"],
    /^LGPL$/xi => ["http://www.gnu.org/licenses/lgpl-3.0", "gnu/lgpl-v3-logo.svg"],
    /^AGPL$/xi => ["http://www.gnu.org/licenses/agpl-3.0", "gnu/agpl-v3-logo.svg"],
    /^GFDL$/xi => ["http://www.gnu.org/licenses/fdl-1.3", "gnu/gfdl-logo.svg"],

    # GNU v3 licenses
    /^GPLv3$/xi => ["http://www.gnu.org/licenses/gpl-3.0", "gnu/gpl-v3-logo.svg"],
    /^LGPLv3$/xi => ["http://www.gnu.org/licenses/lgpl-3.0", "gnu/lgpl-v3-logo.svg"],
    /^AGPLv3$/xi => ["http://www.gnu.org/licenses/agpl-3.0", "gnu/agpl-v3-logo.svg"],

    # GNU v2 licenses
    /^GPLv2$/xi => ["http://www.gnu.org/licenses/gpl-2.0", nil],
    /^LGPL23$/xi => ["http://www.gnu.org/licenses/lgpl-2.0", nil],
    /^AGPLv2$/xi => ["http://www.gnu.org/licenses/agpl-2.0", nil],
  }

  # Takes a license string à la "CC-BY-SA 2.5", "CC-BY", "GPLv3", etc.
  # and matches it against all the regular expressions found in the
  # LICENSES array. The first one that matches will be used to determine
  # the license’s online URL and the path to the icon we use to display
  # it.
  #
  # This method returns a hash with the following keys:
  # [:url]
  #   If we know the URL of the license, this is a string with
  #   the URL. If this is +nil+, you should have some other means
  #   of displaying the license to the user.
  # [:icon]
  #   If we have a nice icon for this license, this is an absolute
  #   Pathname pointing to it. If we don’t have one, this is the
  #   absolute Pathname to the default license icon.
  def self.decompose_license(str)
    result = {:url => nil, :icon => OpenRubyRMK::GTKFrontend::ICONS_DIR.join("licenses", DEFAULT_ICON_NAME)}
    LICENSES.each_pair do |regexp, (url, icon_path)|
      if str =~ regexp
        result[:url]  = url if url
        result[:icon] = OpenRubyRMK::GTKFrontend::ICONS_DIR.join("licenses", icon_path) if icon_path
      end
    end

    result
  end

end