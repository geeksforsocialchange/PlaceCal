# frozen_string_literal: true

class Components::PartnerPreview < Components::Base
  prop :partner, ::Partner
  prop :site, ::Site

  def view_template
    li do
      div(class: 'grid gap-x-4 grid-cols-[1fr_auto] border-b-[3px] border-base-rules') do
        h3(class: '!my-0 py-2 self-center text-[1.33333rem] [&_a]:no-underline [&_a:hover]:underline') do
          link_to(@partner.name, @partner, data: { turbo_frame: '_top', turbo_action: 'replace' })
        end
        if show_neighbourhood?
          css = "neighbourhood #{primary_neighbourhood? ? 'neighbourhood--primary' : 'neighbourhood--secondary'} self-center [&_span]:!mt-0"
          div(class: css) { span { neighbourhood_name } }
        end
      end

      if @partner.description
        div do
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
