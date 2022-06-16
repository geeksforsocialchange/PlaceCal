# frozen_string_literal: true

# app/helpers/articles_helper.rb
module ArticlesHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:id, :name)
  end

  def article_partner_links(article)
    article.partners.map { |partner|
      link_to(partner.name, partner_path(partner))
    }.join(', ').html_safe
  end

  def article_summary_text(article)
    truncate article.body.to_s.strip, length: 200, separator: ' '
  end
end
