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
  # Shares its text and logo rows with the cards beside it, so the logos start level across the grid.
  prop :subgrid, _Boolean, default: false

  def view_template
    UI::Card(class: @subgrid ? 'grid grid-rows-subgrid row-span-2 gap-y-0' : 'flex flex-col') do
      div do
        div(class: 'mb-3 text-secondary-strong') { icon(@icon, size: '7') } if @icon
        UI::Heading(level: @heading_level, size: :item, spacing: :xs, balance: true) { @title }
        UI::Text(variant: :lede, tone: :muted, spacing: :none, pretty: true) { @body }
      end
      render_brands if @brands.any?
    end
  end

  private

  def render_brands
    div(class: @subgrid ? 'pt-4 text-tertiary' : 'mt-auto pt-4 text-tertiary') do
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
