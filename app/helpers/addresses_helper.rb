# frozen_string_literal: true

module AddressesHelper
  def options_for_addresses
    Address.all.collect { |p| [p.to_s, p.id] }
  end
end
