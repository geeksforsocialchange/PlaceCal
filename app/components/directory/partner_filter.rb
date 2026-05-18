# frozen_string_literal: true

class Components::Directory::PartnerFilter < Components::Directory::Base
  include Phlex::Rails::Helpers::FormWith

  prop :query, _Nilable(String), default: nil
  prop :categories, _Interface(:each), default: -> { [] }
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :neighbourhoods, _Interface(:each), default: -> { [] }
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil

  def view_template
    form(action: partners_path, method: 'get',
         class: 'bg-home-background-3 rounded-card p-4 mb-4') do
      div(class: 'flex flex-wrap gap-3 items-end') do
        render_search_field
        render_select('category', 'Category', @categories, @selected_category)
        render_select('partnership', 'Partnership', @partnerships_list, @selected_partnership)
        render_select('neighbourhood', 'Neighbourhood', @neighbourhoods, @selected_neighbourhood)
        render_buttons
      end
    end
  end

  private

  def render_search_field
    div(class: 'flex-1 min-w-[200px]') do
      label(for: 'q', class: 'block allcaps-label text-tertiary mb-1') { 'Search' }
      input(
        type: 'text', name: 'q', id: 'q', value: @query,
        placeholder: 'Name or keyword…',
        class: 'w-full border-2 border-rules rounded-full px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
      )
    end
  end

  def render_select(name, label_text, items, selected)
    return if items.none?

    div(class: 'min-w-[160px]') do
      label(for: name, class: 'block allcaps-label text-tertiary mb-1') { label_text }
      select(
        name: name, id: name,
        class: 'w-full border-2 border-rules rounded-full px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors appearance-none cursor-pointer'
      ) do
        option(value: '') { "All #{label_text.downcase.pluralize}" }
        items.each do |item|
          opts = { value: item[:id].to_s }
          opts[:selected] = true if selected.to_s == item[:id].to_s
          option(**opts) { "#{item[:name]} (#{item[:count]})" }
        end
      end
    end
  end

  def render_buttons
    div(class: 'flex gap-2 items-end') do
      button(type: 'submit',
             class: 'bg-foreground text-background rounded-full px-5 py-2 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors') do
        plain 'Filter'
      end
      if any_filter_active?
        a(href: partners_path,
          class: 'inline-flex items-center rounded-full px-4 py-2 text-sm font-bold text-tertiary border-2 border-rules no-underline hover:border-foreground transition-colors') do
          plain 'Clear'
        end
      end
    end
  end

  def any_filter_active?
    @query.present? || @selected_category.present? || @selected_partnership.present? || @selected_neighbourhood.present?
  end
end
