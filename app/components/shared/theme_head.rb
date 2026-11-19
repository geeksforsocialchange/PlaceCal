# frozen_string_literal: true

# A theme's stylesheet, webfont and head component, shared by the site and Lookbook layouts.
class Components::Shared::ThemeHead < Components::Base
  include Phlex::Rails::Helpers::StylesheetLinkTag

  prop :theme, PlaceCal::Theme

  def view_template
    stylesheet_link_tag @theme.stylesheet_path, media: 'all', 'data-turbo-track': 'reload' if @theme.stylesheet_path
    render_font_stylesheet
    render @theme.head_class.new if @theme.head_class
  end

  private

  # `theme.font_stylesheet url, preconnect: [...]`. The stylesheet loads as print media and switches to all
  # once it arrives (Phlex refuses on* attributes, hence raw), so the webfont never holds up the first paint.
  def render_font_stylesheet
    font = @theme.font_stylesheet
    return if font.nil?

    font[:preconnect].each { |origin| link(rel: 'preconnect', href: origin, crossorigin: true) }
    link(rel: 'preload', as: 'style', href: font[:url])
    raw safe(%(<link rel="stylesheet" href="#{ERB::Util.html_escape(font[:url])}" media="print" onload="this.media='all'">))
    noscript { link(rel: 'stylesheet', href: font[:url]) }
  end
end
