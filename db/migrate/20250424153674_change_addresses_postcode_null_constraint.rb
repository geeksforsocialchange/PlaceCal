# frozen_string_literal: true

class ChangeAddressesPostcodeNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :addresses, :postcode, false
  end
end
