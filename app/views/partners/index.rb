# frozen_string_literal: true

class Views::Partners::Index < Views::Base
  prop :partners, _Any, reader: :private
  prop :site, _Any, reader: :private
  prop :current_site, _Any, reader: :private
  prop :map, _Nilable(_Any), reader: :private
  prop :selected_category, _Nilable(_Any), reader: :private
  prop :selected_neighbourhood, _Nilable(_Any), reader: :private

  def view_template
    content_for(:title) { 'Partners' }
    content_for(:image) { site.og_image }
    content_for(:description) { site.og_description }

    render(Components::Hero.new('Our Partners', site.tagline))
    turbo_frame_tag 'partner_previews' do
      div(class: 'c c--lg-space-after') do
        render(Components::Breadcrumb.new(trail: [['Partners', partners_path]], site_name: site.name)) do
          render Components::PartnerFilter.new(
            site: site,
            selected_category: selected_category,
            selected_neighbourhood: selected_neighbourhood
          )
        end

        hr

        ul(class: 'partners reset two-col', id: 'partners') do
          partners.each do |partner|
            render Components::PartnerPreview.new(partner: partner, site: site)
          end
        end
      end
      div(id: 'map') do
        render Components::Map.new(points: map, site: current_site.slug)
      end
    end
  end
end
