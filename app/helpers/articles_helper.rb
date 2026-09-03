# frozen_string_literal: true

# app/helpers/articles_helper.rb
module ArticlesHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:name, :id)
  end

  def article_partner_links(article)
    article.partners.map do |partner|
      link_to(partner.name, partner_path(partner))
    end.join(' | ').html_safe
  end

  # Plain-text excerpt: the body is markdown, so render it and strip the tags
  # rather than showing raw syntax in listings.
  def article_summary_text(article)
    html = Kramdown::Document.new(article.body.to_s).to_html
    text = ActionController::Base.helpers.strip_tags(html).squish
    truncate text, length: 200, separator: ' '
  end
end
