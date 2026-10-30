# frozen_string_literal: true

class Components::Directory::PartnerFilter < Components::Directory::Base
  include Phlex::Rails::Helpers::FormWith

  prop :query, _Nilable(String), default: nil
  prop :categories, _Interface(:each), default: -> { [] }
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :neighbourhoods_tree, _Interface(:each), default: -> { [] }
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil

  def view_template
    UI::Card(variant: :panel, padding: :sm, tag: :form, action: partners_path, method: 'get') do
      div(class: 'text-sm') do
        UI::Stack(gap: :sm_md) do
          UI::Cluster(gap: :sm_md, align: :end, nowrap_from: :lg) do
            render_search_field
            if @categories.any?
              UI::Select(name: 'category', label_text: t('directory.filters.category'),
                         default_label: t('directory.filters.all_categories'), options: @categories, selected: @selected_category)
            end
            if @partnerships_list.any?
              UI::Select(name: 'partnership', label_text: t('directory.filters.partnership'),
                         default_label: t('directory.filters.all_partnerships'), options: @partnerships_list, selected: @selected_partnership)
            end
          end
          UI::Cluster(gap: :sm_md, align: :end) do
            Directory::NeighbourhoodCascade(tree: @neighbourhoods_tree, selected: @selected_neighbourhood, label_text: t('directory.filters.neighbourhood')) if @neighbourhoods_tree.any?
            render_buttons
          end
        end
      end
    end
  end

  private

  def render_search_field
    # Full width on its own line when wrapped, so Category and Partnership get a
    # roomy half each instead of three cramped columns; shares the row on lg.
    UI::Field(label: t('directory.filters.search'), id: 'q', class: 'flex-1 basis-full lg:basis-auto min-w-35') do
      UI::Input(name: 'q', id: 'q', value: @query, placeholder: t('directory.filters.search_placeholder'))
    end
  end

  def render_buttons
    UI::Cluster(gap: :sm, align: :end, wrap: false) do
      UI::Button(variant: :dark, size: :sm, shape: :field, type: 'submit') { t('directory.filters.apply') }
      UI::Button(variant: :dark_outline, size: :sm, shape: :field, href: partners_path) { t('directory.filters.clear') } if any_filter_active?
    end
  end

  def any_filter_active?
    @query.present? || @selected_category.present? || @selected_partnership.present? || @selected_neighbourhood.present?
  end
end
