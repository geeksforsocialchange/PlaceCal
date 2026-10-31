# frozen_string_literal: true

class Views::Directory::Partnerships::Index < Views::Base
  prop :partnerships, _Interface(:each)
  prop :site, _Nilable(::Site), default: nil
  prop :query, _Nilable(String), default: nil
  prop :partnership_count, Integer, default: 0
  prop :total_partners, Integer, default: 0

  def view_template
    content_for(:title) { Partnership.model_name.human(count: 2) }
    content_for(:description) { "Explore #{@partnership_count} partnerships serving #{@total_partners} partners on PlaceCal." }

    Directory::PageHero(
      title: t('directory.partnerships.index.hero_title'),
      kicker: t('directory.partnerships.index.hero_kicker', count: @partnership_count, partners: @total_partners),
      subtitle: t('directory.partnerships.index.hero_subtitle'),
      breadcrumb_label: Partnership.model_name.human(count: 2)
    )

    div(class: 'container-public py-6') do
      UI::Stack(gap: :lg) do
        render_search
        if partnership_list.any?
          div(class: 'lg:columns-2 gap-x-4') do
            partnership_list.each do |partnership|
              Directory::PartnershipCard(partnership:)
            end
          end
        else
          render_empty_state
        end
      end
    end
  end

  private

  def render_search
    UI::SearchBar(action: partnerships_path, value: @query, size: :sm, width: :md,
                  placeholder: t('directory.partnerships.index.search_placeholder'),
                  button_label: t('directory.partnerships.index.search_button'))
  end

  def render_empty_state
    Directory::EmptyState(
      message: t('directory.partnerships.index.empty'),
      link_text: (t('directory.partnerships.index.clear_search') if @query.present?),
      link_href: (partnerships_path if @query.present?)
    )
  end

  def partnership_list
    @partnership_list ||= Array(@partnerships)
  end
end
