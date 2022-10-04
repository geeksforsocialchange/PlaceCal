# frozen_string_literal: true

class FixInvalidPartners < ActiveRecord::Migration[6.0]
  def up
    invalid_partners = Partner.all.reject(&:valid?)
    invalid_partners.each do |partner|
      partner.valid?
      invalid_fields = partner.errors.messages

      invalid_fields.each do |field, _error|
        if %i[partner_phone public_phone].include?(field)
          partner.public_phone = partner.public_phone&.strip
          partner.partner_phone = partner.partner_phone&.strip
        elsif field == :twitter_handle
          partner.twitter_handle = partner.twitter_handle.delete('@').strip
        elsif field == :facebook_link
          facebook_link = partner.facebook_link.scan(%r{(?:https?://)?(?:www.)?facebook.com/(?:pg/)?(\w*)/?})
          partner.facebook_link = facebook_link.flatten[0]&.strip
        elsif field == :url
          partner.url = if partner.url.starts_with?('www')
                          "https://#{partner.url}"&.strip
                        else
                          "https://www.#{partner.url}"&.strip
                        end
        end
      end

      partner.save(validate: false)
    end
  end

  def down; end
end
