# frozen_string_literal: true

class Components::Sites::Breadcrumb < Components::Base
  prop :trail, Array, default: -> { [] }
  prop :site_name, String, default: 'The Community Calendar'

  ELEMENT = 'breadcrumb__element flex items-center gap-1 mr-2 max-md:mb-2'
  # The filters and actions a page passes in: their own row below the trail, beside it from xl.
  SLOT = 'breadcrumb__slot w-full max-md:mb-2 xl:w-auto xl:flex-auto'
  LINK = 'text-foreground no-underline border-b-2 border-rules-dark'

  def view_template(&)
    div(class: 'breadcrumb flex flex-wrap text-sm mt-2 md:my-4 print:hidden') do
      div(class: "#{ELEMENT} max-md:hidden") do
        link_to(@site_name, '/', class: LINK)
      end
      @trail.each do |link|
        div(class: ELEMENT) do
          raw(view_context.icon(:triangle_right, size: nil, css_class: 'size-em shrink-0 text-primary'))
          link_to(link[0], link[1], class: LINK)
        end
      end
      UI::Cluster(gap: :md, row_gap: :sm, justify: :end, justify_from: :xl, class: SLOT, &)
    end

    emit_breadcrumb_json_ld
  end

  private

  def emit_breadcrumb_json_ld
    base = request.base_url
    items = [{ '@type' => 'ListItem', 'position' => 1, 'name' => @site_name, 'item' => "#{base}/" }]

    @trail.each_with_index do |link, index|
      items << { '@type' => 'ListItem', 'position' => index + 2, 'name' => link[0], 'item' => "#{base}#{link[1]}" }
    end

    data = { '@context' => 'https://schema.org', '@type' => 'BreadcrumbList', 'itemListElement' => items }
    script(type: 'application/ld+json') { raw safe(data.to_json) }
  end
end
