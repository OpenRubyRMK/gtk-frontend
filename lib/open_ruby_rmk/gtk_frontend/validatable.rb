# -*- coding: utf-8 -*-
# Rails/ActiveRecord-style validations for dialogs.
# To use it, call ClassMethods#validate in your
# validating class and define your validation code
# with it. Later, call #valid? or #validate? to run
# this code on a modified instance. Finally, inspect
# the encountered validation errors in #validation_errors.
module OpenRubyRMK::GTKFrontend::Validatable

  # Class methods automatically added to the class
  # including the Validatable module.
  module ClassMethods

    # Main validation method. Call once in your class
    # and supply your validation code as a block to
    # this method. Inside the block, you want to
    # call Validatable#val_error whenever you encounter
    # something incorrect.
    # +self+ is set to the validating instance for the
    # block.
    def validate(&block)
      @validation_block = block
    end

  end

  # When this module gets included, also extend ClassMethods
  # onto the including class.
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  # Remembers the validation error message +msg+.
  # After calling this, #valid? will return false.
  def val_error(msg)
    @val_errors ||= []
    @val_errors << msg
  end

  # Calls #validate and returns true if no validation
  # errors have been found, false otherwise.
  def valid?
    validate
    @val_errors.empty?
  end

  # Main validation method. Executes the block registered
  # via ClassMethods#validate in the context of +self+.
  # After this method returns, you want to check the
  # #validation_errors array for a list of encountered
  # errors.
  def validate
    @val_errors = [] # Always clear it before validating
    validator = self.class.instance_variable_get(:@validation_block)
    instance_eval(&validator)
  end

  # An array of the strings you passed to #val_error or
  # an empty array if no errors occured.
  def validation_errors
    @val_errors || []
  end

  # All #validation_errors concatenated to a single,
  # multiline string ready for display to the user.
  def validation_summary
    if validation_errors.count == 1
      validation_errors.first
    else
      validation_errors.map{|msg| "• #{msg}"}.join("\n")
    end
  end

end
