# frozen_string_literal: true

module Admin
  # Interactive opening times editor with Stimulus controller.
  # Allows users to add/remove opening times for each day of the week.
  #
  # @example Usage in a form
  #   <%= render Admin::OpeningTimesComponent.new(form: f, partner: @partner) %>
  #
  class OpeningTimesComponent < ViewComponent::Base
    # @param form [ActionView::Helpers::FormBuilder] The form builder
    # @param partner [Partner] The partner being edited
    def initialize(form:, partner:)
      super()
      @form = form
      @partner = partner
    end

    private

    attr_reader :form, :partner

    def opening_times_json
      partner.opening_times_data
    end

    def opening_times?
      partner.opening_times.present?
    end

    # Returns day names ordered Monday-Sunday
    def ordered_day_names
      day_names = I18n.t('date.day_names')
      [1, 2, 3, 4, 5, 6, 0].map { |i| day_names[i] }
    end
  end
end
