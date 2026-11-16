# frozen_string_literal: true

# One group of features under its own heading, with a link to the page that backs it up.
class Components::Join::FeatureGroup < Components::Join::Base
  LINK_PATHS = { 'accessibility' => '/accessibility', 'sustainability' => '/sustainability', 'mcp' => '/mcp', 'directory' => '/' }.freeze
  SOURCE_CODE_URL = 'https://github.com/geeksforsocialchange/PlaceCal'

  prop :group, Hash

  def view_template
    section(id: @group[:key], aria_labelledby: "#{@group[:key]}-heading") do
      UI::Heading(id: "#{@group[:key]}-heading", spacing: :xs) { @group[:title] }
      UI::Text(variant: :lede, tone: :muted, measure: :prose, spacing: :lg) { @group[:summary] }
      UI::Grid(cols: { md: 2, lg: @group[:items].size == 3 ? 3 : 4 }) do
        @group[:items].each { |item| Join::FeatureCard(title: item[:title], body: item[:body]) }
      end
      render_link if @group[:link]
    end
  end

  private

  def render_link
    div(class: 'mt-4') do
      UI::Link(href: link_href, variant: :action) do
        plain @group[:link_label]
        span(aria_hidden: 'true') { safe(' &rarr;') }
      end
    end
  end

  def link_href
    return SOURCE_CODE_URL if @group[:link] == 'source_code'

    "#{apex_url}#{LINK_PATHS.fetch(@group[:link])}".delete_suffix('/')
  end
end
