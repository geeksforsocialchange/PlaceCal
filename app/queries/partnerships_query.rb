# frozen_string_literal: true

# Query object for the directory partnerships index.
#
# Partnerships are published Sites, ordered by partner count, optionally
# filtered by a keyword search over name and description.
#
# @example
#   PartnershipsQuery.new.call(query: "manchester")
#
class PartnershipsQuery
  # @param query [String] keyword search on name/description
  # @return [ActiveRecord::Relation<Site>]
  def call(query: nil)
    partnerships = Site.published.order(partners_count: :desc)
    partnerships = filter_by_query(partnerships, query) if query.present?
    partnerships
  end

  private

  def filter_by_query(partnerships, query)
    partnerships.where('sites.name ILIKE :q OR sites.description ILIKE :q', q: "%#{query}%")
  end
end
