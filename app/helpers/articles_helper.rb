# frozen_string_literal: true

# app/helpers/articles_helper.rb
module ArticlesHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:name, :id)
  end

  # Partners the current user may attach an article to. Root and editor manage
  # all articles (issue #2045), so they can attach any partner; everyone else
  # is limited to the partners they administer.
  def options_for_article_partners
    scope = current_user.root? || current_user.editor? ? Partner.all : policy_scope(Partner)
    scope.order(:name).pluck(:name, :id)
  end

  def article_partner_links(article)
    article.partners.map do |partner|
      link_to(partner.name, partner_path(partner))
    end.join(' | ').html_safe
  end

  def article_summary_text(article)
    truncate article.body.to_s.strip, length: 200, separator: ' '
  end
end
