# frozen_string_literal: true

class Components::Join::FeatureCard < Components::Join::Base
  register_output_helper :icon

  prop :title, String
  prop :body, String
  # 2 when the grid sits directly under the page h1, so heading order never skips.
  prop :heading_level, Integer, default: 3
  prop :icon, _Nilable(Symbol), default: nil
  # Logos of the products the card names; decorative, since the text names them.
  prop :brands, _Array(Symbol), default: -> { [] }

  def view_template
    UI::Card(class: 'flex flex-col') do
      div(class: 'mb-3 text-secondary-strong') { icon(@icon, size: '7') } if @icon
      UI::Heading(level: @heading_level, size: :item, spacing: :xs, balance: true) { @title }
      UI::Text(variant: :lede, tone: :muted, spacing: :none, pretty: true) { @body }
      render_brands if @brands.any?
    end
  end

  private

  def render_brands
    div(class: 'mt-auto pt-4 text-tertiary') do
      UI::Cluster(gap: :sm_md) { @brands.each { |brand| render_brand(brand) } }
    end
  end

  # Brands with no vector logo anywhere free use a one-colour PNG in app/assets/images/brands.
  def render_brand(brand)
    if SvgIconsHelper::ICONS.key?(:"brand_#{brand}")
      icon(:"brand_#{brand}", size: '5')
    else
      image_tag("brands/#{brand}.png", alt: '', class: 'size-5')
    end
  end
end
