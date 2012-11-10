module OpenRubyRMK::GTKFrontend::Errors

  # Base class for all exceptions in this library.
  class GTKFrontendError < OpenRubyRMK::Backend::Errors::OpenRubyRMKError
  end

  # The user entered something bad.
  class ValidationError < GTKFrontendError
  end

end
