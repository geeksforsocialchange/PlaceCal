# frozen_string_literal: true

module Admin
  # Renders a group of related radio-style filters in a single fieldset
  # Used when multiple related filters should be visually grouped together
  #
  # @example Usage with multiple filters
  #   <%= render Admin::RadioFilterGroupComponent.new(
  #     group_label: 'Permissions',
  #     filters: [
  #       { column: 'role', label: 'Role', options: [...] },
  #       { column: 'admin_type', label: 'Admin', options: [...] }
  #     ]
  #   ) %>
  #
  class RadioFilterGroupComponent < ViewComponent::Base
    # @param group_label [String] The legend for the grouped fieldset
    # @param filters [Array<Hash>] Array of filter hashes with :column, :label, :options keys
    # @param show_all [Boolean] Whether to show "All" buttons (default: true)
    def initialize(group_label:, filters:, show_all: true)
      super()
      @group_label = group_label
      @filters = filters
      @show_all = show_all
    end

    attr_reader :group_label, :filters, :show_all
  end
end
