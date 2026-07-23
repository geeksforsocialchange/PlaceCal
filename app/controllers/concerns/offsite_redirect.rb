# frozen_string_literal: true

# A partner or event page served on a subdomain it doesn't belong to is
# duplicate content that search engines index despite the canonical tag
# (#1722), so 301 to the canonical apex URL instead of rendering it.
# Callers should follow with `return if performed?`.
module OffsiteRedirect
  extend ActiveSupport::Concern

  private

  def redirect_offsite_to_permalink(query, record)
    return if current_site.nil? || query.include?(record)

    redirect_to record.permalink, status: :moved_permanently, allow_other_host: true
  end
end
