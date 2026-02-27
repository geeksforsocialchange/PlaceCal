# frozen_string_literal: true

class Components::PartnerPreview < Components::Base
  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    li(class: 'preview') do
      div(class: 'preview__header') do
        h3 { link_to(@partner.name, @partner, data: { turbo_frame: '_top', turbo_action: 'replace' }) }
        if show_neighbourhood?
          css = "neighbourhood #{primary_neighbourhood? ? 'neighbourhood--primary' : 'neighbourhood--secondary'} preview__neighbourhood"
          div(class: css) { span { neighbourhood_name } }
        end
      end

      if @partner.description
        div(class: 'preview__details') do
          comment { "Categories: #{@partner.categories.map(&:name).join(', ')}" }
          p { @partner.summary }
        end
      end
    end
  end

  private

  def show_neighbourhood?
    @site.show_neighbourhoods? || @partner.neighbourhoods.any?
  end

  def neighbourhood_name
    @partner.neighbourhood_name_for_site(@site.badge_zoom_level)
  end

  def primary_neighbourhood?
    return true unless @site.primary_neighbourhood

    @site.primary_neighbourhood && (@partner.address&.neighbourhood == @site.primary_neighbourhood)
  end
end
