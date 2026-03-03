# frozen_string_literal: true

class Views::Partners::Index < Views::Base
  prop :partners, ActiveRecord::Relation, reader: :private
  prop :site, Site, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :selected_category, _Nilable(String), reader: :private
  prop :selected_neighbourhood, _Nilable(String), reader: :private

  def view_template
    content_for(:title) { 'Partners' }
    content_for(:image) { site.og_image }
    content_for(:description) { site.og_description }

    Hero('Our Partners', site.tagline)
    turbo_frame_tag 'partner_previews' do
      div(class: 'c c--lg-space-after') do
        Breadcrumb(trail: [['Partners', partners_path]], site_name: site.name) do
          PartnerFilter(
            site: site,
            selected_category: selected_category,
            selected_neighbourhood: selected_neighbourhood
          )
        end

        hr

        ul(class: 'partners reset two-col', id: 'partners') do
          partners.each do |partner|
            PartnerPreview(partner: partner, site: site)
          end
        end
      end
      div(id: 'map') do
        Map(points: map, site: site.slug)
      end
    end
  end
end
