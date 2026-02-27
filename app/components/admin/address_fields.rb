# frozen_string_literal: true

class Components::Admin::AddressFields < Components::Admin::Base
  include ApplicationHelper

  prop :form, ActionView::Helpers::FormBuilder
  prop :partner, ::Partner
  prop :current_user, ::User

  def view_template
    raw @form.fields_for(:address, address) { |address_form|
      capture do
        div(
          class: 'nested-fields',
          data_controller: 'partner-address',
          data_partner_address_partner_id_value: @partner.id,
          data_partner_address_warn_of_delisting_value: warn_of_delisting_value
        ) do
          address_field_configs.each do |field_config|
            fieldset(class: 'fieldset') do
              legend(class: 'fieldset-legend') { attr_label(:address, field_config[:label_key]) }
              raw address_form.input_field(field_config[:field],
                                           class: 'input input-bordered w-full bg-base-100 address_field')
            end
          end

          div(data_partner_address_target: 'addressInfoArea', class: 'mt-4') do
            if can_clear_address?
              link_to t('admin.address.clear_address'), '#',
                      class: 'btn btn-ghost btn-xs',
                      data: { action: 'click->partner-address#do_clear_address' }
            end
          end
        end
      end
    }
  end

  private

  def address
    @partner.address || Address.new
  end

  def warn_of_delisting_value
    @partner.warn_user_clear_address?(@current_user) ? 'true' : 'false'
  end

  def can_clear_address?
    @partner.can_clear_address?(@current_user)
  end

  def address_field_configs
    [
      { field: :street_address, label_key: :street_address },
      { field: :street_address2, label_key: :street_address_2 },
      { field: :street_address3, label_key: :street_address_3 },
      { field: :city, label_key: :city },
      { field: :postcode, label_key: :postcode }
    ]
  end
end
