# frozen_string_literal: true

xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss(version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
  xml.channel do
    xml.title @feed_title
    xml.description @feed_description
    xml.link news_index_url
    xml.tag!('atom:link', href: request.original_url, rel: 'self', type: 'application/rss+xml')
    xml.language I18n.locale.to_s

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link news_url(article)
        xml.guid news_url(article)
        xml.pubDate article.published_at.rfc822
        xml.description { xml.cdata!(article.body_html.to_s) }
        article.partners.each { |partner| xml.category partner.name }

        if article.article_image.present? && (image_size = article.article_image.file&.size).to_i.positive?
          xml.enclosure(
            url: "#{request.base_url}#{article.article_image.url}",
            length: image_size,
            type: article.article_image.content_type.presence || 'image/jpeg'
          )
        end
      end
    end
  end
end
