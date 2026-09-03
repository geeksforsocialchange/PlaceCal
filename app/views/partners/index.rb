# frozen_string_literal: true

class Views::Partners::Index < Views::Base
  prop :partners, ActiveRecord::Relation, reader: :private
  prop :site, Site, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :selected_category, _Nilable(String), reader: :private
  prop :selected_neighbourhood, _Nilable(String), reader: :private
  prop :region_tags, Array, reader: :private, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), reader: :private, default: nil

  def view_template
    content_for(:title) { t('partners.index.page_title') }
    content_for(:description) { site.og_description }

    Hero(t('partners.index.title'), site.tagline, standfirst: t('partners.index.standfirst'),
                                                  standfirst_detail: t('partners.index.standfirst_detail'))
    turbo_frame_tag 'partner_previews' do
      div(class: 'container-public mb-32') do
        Breadcrumb(trail: [['Partners', partners_path]], site_name: site.name) do
          PartnerFilter(
            site: site,
            selected_category: selected_category,
            selected_neighbourhood: selected_neighbourhood,
            region_tags: region_tags,
            selected_region: selected_region
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
