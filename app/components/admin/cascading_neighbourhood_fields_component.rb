# frozen_string_literal: true

module Admin
  class CascadingNeighbourhoodFieldsComponent < ViewComponent::Base
    include SvgIconsHelper

    def initialize(form:, show_remove: true, relation_type: nil, title: nil)
      super()
      @form = form
      @show_remove = show_remove
      @relation_type = relation_type
      @title = title
    end

    attr_reader :form, :show_remove, :relation_type, :title
  end
end
