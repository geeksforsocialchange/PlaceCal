# frozen_string_literal: true

class FixPartnerAddressDuplicates < ActiveRecord::Migration[6.1]
  def up
    # so apparently we need to fix some partner names first
    bad_partners = Partner.group(:name).count.keep_if { |_k, v| v > 1 }
    Rails.logger.debug { "Found #{bad_partners.count} partners with duplicate names" }
    Partner.transaction do
      bad_partners.each do |partner_name, count|
        Rails.logger.debug { "  '#{partner_name}' has #{count} duplicates" }
        Partner.where(name: partner_name).all.each do |fix_partner|
          fix_partner.name = "#{fix_partner.name} (#{fix_partner.id})"
          fix_partner.save!
        end
      end
    end

    bad_partners = Partner.group(:address_id).count(:address_id).keep_if { |_key, val| val > 1 }
    Rails.logger.debug { "Found #{bad_partners.count} partners with shared  addresses" }

    bad_partners.each_key do |address_id|
      partners = Partner.where(address_id: address_id)
      partner_primary = partners.first

      Partner.transaction do
        partners[1..].each do |p|
          Rails.logger.debug { "  Fixing partner #{p.id}" }
          p.address = partner_primary.address.dup
          p.save!
        end
      end
    end
  end

  def down; end
end
