# frozen_string_literal: true

class ChangeAddressesStreetAddressNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :addresses, :street_address, false
  end
end
