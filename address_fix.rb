# frozen_string_literal: true

require './config/environment'

bad_partners = Partner.group(:address_id).count(:address_id).keep_if { |_key, val| val > 1 }
bad_partners.each_key do |address_id|
  partners = Partner.where(address_id: address_id)
  partner_primary = partners.first
  partners[1..].each do |p|
    p.address = partner_primary.address.dup
    p.save!
  end
end
