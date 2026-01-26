# frozen_string_literal: true

module Admin
  # Address fields component for partner forms with Stimulus controller integration.
  # Handles nested address attributes with clear address functionality.
  #
  # @example Usage in a form
  #   <%= render Admin::AddressFieldsComponent.new(form: f, partner: @partner, current_user: current_user) %>
  #
  class AddressFieldsComponent < ViewComponent::Base
    include ApplicationHelper

    # @param form [ActionView::Helpers::FormBuilder] The parent form builder
    # @param partner [Partner] The partner being edited
    # @param current_user [User] The current logged-in user
    def initialize(form:, partner:, current_user:)
      super()
      @form = form
      @partner = partner
      @current_user = current_user
    end

    private

    attr_reader :form, :partner, :current_user

    def address
      partner.address || Address.new
    end

    def warn_of_delisting_value
      partner.warn_user_clear_address?(current_user) ? 'true' : 'false'
    end

    def can_clear_address?
      partner.can_clear_address?(current_user)
    end

    def address_fields
      [
        { field: :street_address, label_key: :street_address },
        { field: :street_address2, label_key: :street_address_2 },
        { field: :street_address3, label_key: :street_address_3 },
        { field: :city, label_key: :city },
        { field: :postcode, label_key: :postcode }
      ]
    end
  end
end
