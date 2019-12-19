# frozen_string_literal: true

module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def set_tags
      @tags = if current_user&.role&.root?
                 Tag.all
               else
                 current_user&.tags
               end
    end
  end
end
