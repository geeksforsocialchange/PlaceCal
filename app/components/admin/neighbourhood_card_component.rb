# frozen_string_literal: true

module Admin
  # Displays a neighbourhood with its hierarchy in a compact card format
  # Used in partner location tab and service areas
  class NeighbourhoodCardComponent < ViewComponent::Base
    include SvgIconsHelper
    include NeighbourhoodsHelper

    def initialize(neighbourhood:, show_header: true, show_remove: false, form: nil, inline: false)
      super()
      @neighbourhood = neighbourhood
      @show_header = show_header
      @show_remove = show_remove
      @form = form
      @inline = inline
    end

    private

    attr_reader :neighbourhood, :show_header, :show_remove, :form, :inline

    def ancestors
      @ancestors ||= neighbourhood.ancestors.order(:ancestry)
    end
  end
end
