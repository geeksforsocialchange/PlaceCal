require "administrate/field/base"

class AddressField < Administrate::Field::Associative

  def self.permitted_attribute(attr)
   :"#{attr}_id"
  end

  def addresses
    associated_class.order(:street_address)
  end

  def selected_option
    data && data.send(primary_key)
  end

  def full_address
    data && data.full_address
  end
end
