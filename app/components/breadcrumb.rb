# frozen_string_literal: true

class Components::Breadcrumb < Components::Base
  prop :trail, Array, default: -> { [] }
  prop :site_name, String, default: 'The Community Calendar'

  def view_template(&)
    div(class: 'breadcrumb') do
      div(class: 'breadcrumb__element') do
        span(class: 'breadcrumb__tagline') do
          link_to(@site_name, '/')
        end
      end
      @trail.each do |link|
        div(class: 'breadcrumb__element') do
          raw(view_context.icon(:triangle_right, size: nil))
          link_to(link[0], link[1])
        end
      end
      div(class: 'breadcrumb__element breadcrumb__element--last', &)
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
