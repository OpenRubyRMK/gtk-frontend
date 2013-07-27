module OpenRubyRMK::GTKFrontend::Errors

  # Base class for all exceptions in this library.
  class GTKFrontendError < OpenRubyRMK::Backend::Errors::OpenRubyRMKError
  end

  # The user entered something bad.
  class ValidationError < GTKFrontendError
  end

  # Raised when we encounter a template name and are
  # unable to map that name to a specific Backend::Template
  # instance.
  class UnknownTemplate < GTKFrontendError

    # The identifier we were unable to map.
    attr_reader :identifier

    # Create a new exception of this type.
    def initialize(ident, msg = "Can't find a template named `#{ident}'!")
      @identifier = ident
      super(msg)
    end

  end

end
