# frozen_string_literal: true

class Views::Sites::Partners::Index < Views::Base
  prop :partners, ActiveRecord::Relation, reader: :private
  prop :site, Site, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :selected_category, _Nilable(String), reader: :private
  prop :selected_neighbourhood, _Nilable(String), reader: :private
  prop :region_tags, Array, reader: :private, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), reader: :private, default: nil
  prop :selected_query, _Nilable(String), reader: :private, default: nil
  prop :query, _Nilable(::PartnersQuery), reader: :private, default: nil

  def view_template
    content_for(:title) { t('partners.index.page_title') }
    content_for(:description) { site.og_description }

    Shared::Hero(t('partners.index.title'), site.tagline, standfirst: t('partners.index.standfirst'),
                                                          standfirst_detail: t('partners.index.standfirst_detail'))
    turbo_frame_tag 'partner_previews', data: { turbo_action: 'advance' } do
      div(class: 'container-public mb-32') do
        list_heading('partners.index.list_heading')
        Sites::Breadcrumb(trail: [[t('navigation.site.partners'), partners_path]], site_name: site.name) do
          Sites::PartnerFilter(
            site:,
            selected_category:,
            selected_neighbourhood:,
            region_tags:,
            selected_region:,
            selected_query:,
            query:
          )
        end

        hr

        if partners.empty?
          p(class: 'partners__empty') { t('partners.index.empty') }
        else
          ul(class: 'partners reset two-col', id: 'partners') do
            partners.each do |partner|
              Sites::PartnerPreview(partner:, site:)
            end
          end
        end
      end
      div(id: 'map') do
        Shared::Map(points: map)
      end
    end
  end
end
