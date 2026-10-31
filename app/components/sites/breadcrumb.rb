# frozen_string_literal: true

class Components::Sites::Breadcrumb < Components::Base
  theme_scope :breadcrumb,
              parts: {
                root: 'The trail and the controls a page passes in.',
                crumb: 'One step of the trail: the site\'s name, then each page above this one, each with its arrow icon. The site\'s name hides below md.',
                controls: 'The filters and actions the page passes in: their own row below the trail, beside it from xl.'
              },
              tokens: %i[--text-sm --color-foreground --color-rules-dark --color-primary]

  prop :trail, Array, default: -> { [] }
  prop :site_name, String, default: 'The Community Calendar'

  ELEMENT = 'flex items-center gap-1 mr-2 max-md:mb-2'
  SLOT = 'w-full max-md:mb-2 xl:w-auto xl:flex-auto'
  LINK = 'text-foreground no-underline border-b-2 border-rules-dark'

  def view_template(&)
    div(**part(:root, class: 'flex flex-wrap text-sm mt-2 md:my-4 print:hidden')) do
      div(**part(:crumb, class: "#{ELEMENT} max-md:hidden")) do
        link_to(@site_name, '/', class: LINK)
      end
      @trail.each do |link|
        div(**part(:crumb, class: ELEMENT)) do
          raw(view_context.icon(:triangle_right, size: nil, css_class: 'size-em shrink-0 text-primary'))
          link_to(link[0], link[1], class: LINK)
        end
      end
      UI::Cluster(gap: :md, row_gap: :sm, justify: :end, justify_from: :xl, **part(:controls, class: SLOT), &)
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
