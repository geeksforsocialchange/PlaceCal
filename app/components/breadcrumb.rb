# frozen_string_literal: true

class Components::Breadcrumb < Components::Base
  prop :trail, _Any, default: -> { [] }
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
          span(class: 'icon icon--arrow-right') { plain "\u2192" }
          link_to(link[0], link[1])
        end
      end
      div(class: 'breadcrumb__element breadcrumb__element--last', &)
    end
  end
end
