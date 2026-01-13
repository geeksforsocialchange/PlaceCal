# frozen_string_literal: true

module Admin
  class ErrorComponent < ViewComponent::Base
    def initialize(object)
      super()
      @object = object
    end

    def errors_present?
      @object.errors.any?
    end

    def error_count
      @object.errors.count
    end

    def error_messages
      @object.errors.full_messages
    end

    def object_class_name
      @object.class.name
    end
  end
end
