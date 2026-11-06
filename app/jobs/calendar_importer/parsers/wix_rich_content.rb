# frozen_string_literal: true

module CalendarImporter::Parsers
  # Turns Wix's rich content JSON into HTML for html_sanitize; media nodes are dropped.
  class WixRichContent
    CONTAINER_TAGS = { 'BULLETED_LIST' => 'ul', 'ORDERED_LIST' => 'ol', 'BLOCKQUOTE' => 'blockquote' }.freeze

    def self.to_html(document)
      new.blocks(document['nodes'])
    end

    def blocks(nodes)
      Array(nodes).map { |node| block(node) }.join
    end

    private

    def block(node)
      type = node['type']
      return tagged(CONTAINER_TAGS[type], blocks(node['nodes'])) if CONTAINER_TAGS.key?(type)

      case type
      when 'PARAGRAPH' then paragraphs(node)
      when 'HEADING' then tagged("h#{node.dig('headingData', 'level') || 3}", inline(node))
      when 'LIST_ITEM' then tagged('li', list_item_content(node))
      else ''
      end
    end

    # A blank line inside one Wix paragraph reads as a paragraph break.
    def paragraphs(node)
      inline(node).split(/(?:<br>\s*){2,}/).filter_map do |text|
        text = text.sub(/\A(?:<br>|\s)+/, '').sub(/(?:<br>|\s)+\z/, '')
        tagged('p', text) if text.present?
      end.join
    end

    def list_item_content(node)
      Array(node['nodes']).map { |child| child['type'] == 'PARAGRAPH' ? inline(child).sub(/(?:<br>|\s)+\z/, '') : block(child) }.join
    end

    def inline(node)
      Array(node['nodes']).map { |child| text_html(child['textData']) }.join
    end

    def text_html(data)
      return '' if data.nil?

      html = CGI.escapeHTML(data['text'].to_s).gsub("\n", '<br>')
      return html if html.gsub('<br>', '').blank?

      Array(data['decorations']).reduce(html) { |wrapped, decoration| decorate(wrapped, decoration) }
    end

    def decorate(html, decoration)
      case decoration['type']
      when 'BOLD' then tagged('strong', html)
      when 'ITALIC' then tagged('em', html)
      when 'LINK' then link(html, decoration.dig('linkData', 'link', 'url'))
      else html
      end
    end

    def link(html, url)
      url.present? ? %(<a href="#{CGI.escapeHTML(url)}">#{html}</a>) : html
    end

    def tagged(tag, html)
      "<#{tag}>#{html}</#{tag}>"
    end
  end
end
