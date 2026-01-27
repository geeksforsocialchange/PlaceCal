# frozen_string_literal: true

module Admin
  # Renders a radio-style filter button group for datatables
  #
  # @example Basic usage
  #   <%= render Admin::RadioFilterComponent.new(
  #     column: 'has_events',
  #     label: 'Events',
  #     options: [
  #       { value: 'yes', label: 'Yes' },
  #       { value: 'no', label: 'No' }
  #     ]
  #   ) %>
  #
  class RadioFilterComponent < ViewComponent::Base
    # @param column [String] The datatable column to filter on
    # @param label [String] The legend/label for the filter group
    # @param options [Array<Hash>] Array of { value:, label: } hashes for filter options
    # @param show_all [Boolean] Whether to show an "All" button (default: true)
    def initialize(column:, label:, options:, show_all: true)
      super()
      @column = column
      @label = label
      @options = options
      @show_all = show_all
    end

    attr_reader :column, :label, :options, :show_all
  end
end
