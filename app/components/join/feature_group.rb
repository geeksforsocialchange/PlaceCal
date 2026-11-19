# frozen_string_literal: true

# One group of features under its own heading, with a link to the page that backs it up.
class Components::Join::FeatureGroup < Components::Join::Base
  LINK_PATHS = { 'accessibility' => '/accessibility', 'sustainability' => '/sustainability', 'mcp' => '/mcp', 'directory' => '/' }.freeze
  EXTERNAL_URLS = {
    'handbook' => 'https://handbook.placecal.org/reference/supported-calendar-sources/',
    'source_code' => 'https://github.com/geeksforsocialchange/PlaceCal'
  }.freeze

  prop :group, Hash
  # Alternate groups sit on a tinted band so each reads as its own section.
  prop :banded, _Boolean, default: false

  def view_template
    section(id: @group[:key], class: ['py-12', ('bg-home-background-3' if @banded)], aria_labelledby: "#{@group[:key]}-heading") do
      div(class: 'container-public') do
        UI::Heading(id: "#{@group[:key]}-heading", size: :title, spacing: :xs) { @group[:title] }
        UI::Text(variant: :lede, tone: :muted, measure: :prose, spacing: :lg, pretty: true) { @group[:summary] }
        UI::Grid(cols: { md: 2, lg: @group[:items].size == 3 ? 3 : 4 }) do
          @group[:items].each { |item| Join::FeatureCard(title: item[:title], body: item[:body], icon: item[:icon]&.to_sym, brands: Array(item[:brands]).map(&:to_sym), subgrid: true) }
        end
        render_link if @group[:link]
      end
    end
  end

  private

  def render_link
    div(class: 'mt-4') do
      UI::Button(variant: :dark, href: link_href) do
        plain @group[:link_label]
        span(aria_hidden: 'true') { safe(' &rarr;') }
      end
    end
  end

  def link_href
    return EXTERNAL_URLS[@group[:link]] if EXTERNAL_URLS.key?(@group[:link])

    "#{apex_url}#{LINK_PATHS.fetch(@group[:link])}".delete_suffix('/')
  end
end
