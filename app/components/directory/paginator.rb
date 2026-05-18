# frozen_string_literal: true

class Components::Directory::Paginator < Components::Directory::Base
  prop :pagy, Pagy::Offset

  def view_template
    return unless @pagy.pages > 1

    nav(class: 'flex items-center justify-center gap-1 py-6', aria_label: 'Pagination') do
      render_prev
      render_pages
      render_next
    end
  end

  private

  def render_prev
    if @pagy.previous
      a(href: pagy_url(@pagy.previous), class: pill_class) { safe('&larr;') }
    else
      span(class: "#{pill_class} opacity-30 pointer-events-none") { safe('&larr;') }
    end
  end

  def render_next
    if @pagy.next
      a(href: pagy_url(@pagy.next), class: pill_class) { safe('&rarr;') }
    else
      span(class: "#{pill_class} opacity-30 pointer-events-none") { safe('&rarr;') }
    end
  end

  def render_pages
    page_numbers.each do |item|
      if item == :gap
        span(class: 'px-1 text-tertiary') { plain '...' }
      elsif item == @pagy.page
        span(class: active_pill_class) { plain item.to_s }
      else
        a(href: pagy_url(item), class: pill_class) { plain item.to_s }
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

  def pill_class
    'inline-flex items-center justify-center min-w-[36px] h-9 px-2 rounded-full text-sm font-bold text-foreground no-underline bg-home-background-3 hover:bg-primary transition-colors'
  end

  def active_pill_class
    'inline-flex items-center justify-center min-w-[36px] h-9 px-2 rounded-full text-sm font-bold no-underline bg-foreground text-background'
  end

  def pagy_url(page)
    params = request.query_parameters.merge('page' => page)
    "#{request.path}?#{params.to_query}"
  end
end
