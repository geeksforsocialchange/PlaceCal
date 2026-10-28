# frozen_string_literal: true

class Components::Sites::PartnerPreview < Components::Base
  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    li(class: 'preview') do
      div(class: 'preview__header grid grid-cols-main-auto gap-x-4 border-b-3 border-rules') do
        h3(class: 'my-0 py-2 text-xl self-center') { link_to(@partner.name, partner_path(@partner), class: 'no-underline hover:underline', data: { turbo_frame: '_top', turbo_action: 'replace' }) }
        if show_neighbourhood?
          div(class: 'neighbourhood preview__neighbourhood self-center') { UI::Pill(variant: primary_neighbourhood? ? :neighbourhood : :neighbourhood_outside) { neighbourhood_name } }
        end
      end

      if @partner.description
        div(class: 'preview__details') do
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
