# frozen_string_literal: true

class ChangeAddressesCountryCodeNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :addresses, :country_code, false
  end
end
