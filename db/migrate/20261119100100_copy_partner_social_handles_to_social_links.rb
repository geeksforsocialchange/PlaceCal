# frozen_string_literal: true

class CopyPartnerSocialHandlesToSocialLinks < ActiveRecord::Migration[8.1]
  class MigrationPartner < ActiveRecord::Base
    self.table_name = 'partners'
  end

  def up
    MigrationPartner.reset_column_information
    MigrationPartner.where("social_links = '[]'::jsonb").find_each do |partner|
      links = self.class.links_for(partner)
      partner.update_columns(social_links: links) if links.any? # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    # The old columns are untouched, so there is nothing to undo
  end

  def self.links_for(partner)
    [
      url_for(partner.facebook_link) { "https://www.facebook.com/#{it}" },
      url_for(partner.instagram_handle) { "https://www.instagram.com/#{it}/" },
      url_for(partner.twitter_handle) { "https://x.com/#{it}" }
    ].compact.uniq
  end

  def self.url_for(value)
    value = value.to_s.strip.delete_prefix('@')
    return if value.empty?

    url = value.match?(%r{\Ahttps?://}i) ? value : yield(value)
    url if url.match?(%r{\Ahttps?://\S+\z}i)
  end
end
