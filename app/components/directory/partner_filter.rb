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
    # text-sm on the form so buttons/inputs (which an unlayered `font-size:100%`
    # reset pins to the base size) inherit the same size as the native selects.
    form(action: partners_path, method: 'get',
         class: 'bg-home-background-3 rounded-card p-4 mb-4 text-sm') do
      div(class: 'flex flex-wrap lg:flex-nowrap gap-3 items-end') do
        render_search_field
        Directory::CustomSelect(name: 'category', label_text: 'Category', options: @categories, selected: @selected_category) if @categories.any?
        Directory::CustomSelect(name: 'partnership', label_text: 'Partnership', options: @partnerships_list, selected: @selected_partnership) if @partnerships_list.any?
      end
      div(class: 'flex flex-wrap gap-3 items-end mt-3') do
        Directory::NeighbourhoodCascade(tree: @neighbourhoods_tree, selected: @selected_neighbourhood) if @neighbourhoods_tree.any?
        render_buttons
      end
    end
  end

  private

  def render_search_field
    # Full width on its own line when wrapped, so Category and Partnership get a
    # roomy half each instead of three cramped columns; shares the row on lg.
    div(class: 'flex-1 basis-full lg:basis-auto min-w-35') do
      label(for: 'q', class: 'block allcaps-label text-tertiary mb-1') { 'Search' }
      input(
        type: 'text', name: 'q', id: 'q', value: @query,
        placeholder: 'Name or keyword…',
        class: 'w-full h-[42px] border-2 border-rules rounded-sm px-4 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
      )
    end
  end

  def render_buttons
    div(class: 'flex gap-2 items-end') do
      button(type: 'submit',
             class: 'inline-flex items-center justify-center h-[42px] bg-foreground text-background rounded-sm px-5 text-sm font-bold border-2 border-foreground cursor-pointer hover:bg-tertiary hover:border-tertiary transition-colors') do
        plain 'Filter'
      end
      if any_filter_active?
        a(href: partners_path,
          class: 'inline-flex items-center justify-center h-[42px] rounded-sm px-4 text-sm font-bold bg-background text-foreground border-2 border-foreground no-underline hover:bg-foreground hover:text-background transition-colors') do
          plain 'Clear'
        end
      end
    end
  end

  def any_filter_active?
    @query.present? || @selected_category.present? || @selected_partnership.present? || @selected_neighbourhood.present?
  end
end
