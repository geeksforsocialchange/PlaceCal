# frozen_string_literal: true

# Fits HTML organisers wrote to the page: headings nest under the heading above it without skipping,
# and an image with no alt is decorative rather than read out by filename.
class OrganiserHtml
  HEADINGS = %w[h1 h2 h3 h4 h5 h6].freeze

  def self.call(html, under:)
    new(html, under:).call
  end

  def initialize(html, under:)
    @html = html.to_s
    @under = under
  end

  def call
    return @html if @html.blank?

    fragment = Nokogiri::HTML5.fragment(@html)
    renumber_headings(fragment)
    fragment.css('img:not([alt])').each { |img| img['alt'] = '' }
    fragment.to_html
  end

  private

  def renumber_headings(fragment)
    headings = fragment.css(HEADINGS.join(', '))
    levels = headings.map { |heading| heading.name[1].to_i }.uniq.sort
    target = levels.each_with_index.to_h { |level, rank| [level, [@under + 1 + rank, 6].min] }
    headings.each { |heading| heading.name = "h#{target[heading.name[1].to_i]}" }
  end
end
