# frozen_string_literal: true

module AddressesHelper
  def options_for_addresses
    Address.all.collect { |p| [p.full_address, p.id] }
  end
end
