# frozen_string_literal: true

module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def set_tags
      @tags = (current_user&.role&.root? ? Tag.all : current_user&.tags)
    end
  end
end
