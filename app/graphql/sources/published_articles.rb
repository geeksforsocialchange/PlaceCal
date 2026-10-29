# frozen_string_literal: true

module Sources
  # Each partner's newest published articles, at most `limit` per partner, in one query
  class PublishedArticles < GraphQL::Dataloader::Source
    def initialize(limit)
      super()
      @limit = limit
    end

    def fetch(partner_ids)
      ranked = Article.published.joins(:article_partners).where(article_partners: { partner_id: partner_ids })
                      .select('articles.*, article_partners.partner_id, ' \
                              'ROW_NUMBER() OVER (PARTITION BY article_partners.partner_id ORDER BY published_at DESC, articles.id DESC) AS position')
      articles = Article.from(ranked, :articles).where(position: ..@limit).by_publish_date.group_by(&:partner_id)
      partner_ids.map { |id| articles.fetch(id, []) }
    end
  end
end
