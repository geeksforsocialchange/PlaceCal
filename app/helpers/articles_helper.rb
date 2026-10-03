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

  # Plain-text excerpt of an article body for listings: the body is markdown,
  # so render it and strip the tags rather than showing raw syntax. Cut to a
  # fixed 200 characters on a word boundary.
  #
  # Take the text through Nokogiri rather than strip_tags: strip_tags returns
  # entity-encoded text, which truncate would then escape a second time, so an
  # "&" in the body would reach the page as a literal "&amp;". Nokogiri decodes
  # the entities once and lets us drop script and style content entirely.
  # truncate does the single escape, so no markup from the body reaches the
  # page as HTML.
  def article_summary_text(article)
    html = Kramdown::Document.new(article.body.to_s).to_html
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css('script, style').each(&:remove)
    truncate fragment.text.squish, length: 200, separator: ' '
  end

  # Formats a date with an article date_format locale pattern, substituting
  # `%o` for the ordinal day (2nd, 3rd) before strftime. Mirrors
  # Components::Event#formatted_date so a theme can set a `date_format` such
  # as "%o %B %Y" for either the news index or the article byline.
  #
  # @param date [Date, Time] the date to format
  # @param format [String] a strftime pattern, may contain `%o`
  # @return [String] the formatted date
  def article_date(date, format)
    date.strftime(format.gsub('%o', date.day.ordinalize))
  end
end
