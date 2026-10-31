# frozen_string_literal: true

class Components::Sites::PartnerPreview < Components::Base
  theme_scope :partner_preview,
              parts: {
                root: 'One partner in the partners list.',
                header: 'The row holding the partner\'s name, linked, and the neighbourhood badge.',
                neighbourhood: 'The neighbourhood badge, holding a pill. Only when the site shows neighbourhoods or the partner has one.',
                details: 'The partner\'s summary. Only when the partner has a description.'
              },
              tokens: %i[--color-foreground --color-primary --color-rules --font-weight-bold --text-xl]

  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    li(**part(:root)) do
      div(**part(:header, class: 'grid grid-cols-main-auto gap-x-4 border-b-3 border-rules')) do
        h3(class: 'my-0 py-2 text-xl self-center') { link_to(@partner.name, partner_path(@partner), class: 'no-underline hover:underline', data: { turbo_frame: '_top', turbo_action: 'replace' }) }
        div(**part(:neighbourhood, class: 'neighbourhood self-center')) { UI::Pill(variant: :neighbourhood) { neighbourhood_name } } if show_neighbourhood?
      end

      if @partner.description
        div(**part(:details)) do
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
end
