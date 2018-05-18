# frozen_string_literal: true

require 'administrate/field/base'

class AddressField < Administrate::Field::Associative
  def self.permitted_attribute(attr)
    :"#{attr}_id"
  end

  def addresses
    associated_class.order(:street_address)
  end

  def selected_option
    data&.send(primary_key)
  end

  def full_address
    data&.full_address
  end
end
