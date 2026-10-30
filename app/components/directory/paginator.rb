# frozen_string_literal: true

class Components::Directory::Paginator < Components::Directory::Base
  prop :pagy, Pagy::Offset

  def view_template
    return unless @pagy.pages > 1

    nav(class: 'flex items-center justify-center gap-1 py-6', aria_label: t('directory.aria.pagination')) do
      render_prev
      render_pages
      render_next
    end
  end

  private

  def render_prev
    UI::Pill(variant: :page, href: (pagy_url(@pagy.previous) if @pagy.previous), disabled: !@pagy.previous) { safe('&larr;') }
  end

  def render_next
    UI::Pill(variant: :page, href: (pagy_url(@pagy.next) if @pagy.next), disabled: !@pagy.next) { safe('&rarr;') }
  end

  def render_pages
    page_numbers.each do |item|
      if item == :gap
        span(class: 'px-1 text-tertiary') { plain '...' }
      else
        UI::Pill(variant: :page, href: pagy_url(item), selected: item == @pagy.page) { plain item.to_s }
      end
    end
  end

  def page_numbers
    last = @pagy.pages
    current = @pagy.page
    window = 2

    pages = [1]
    ((current - window)..(current + window)).each do |p|
      pages << p if p > 1 && p < last
    end
    pages << last if last > 1

    result = []
    pages.each_with_index do |p, i|
      result << :gap if i.positive? && p > pages[i - 1] + 1
      result << p
    end
    result
  end

  def pagy_url(page)
    params = request.query_parameters.merge('page' => page)
    "#{request.path}?#{params.to_query}"
  end
end
