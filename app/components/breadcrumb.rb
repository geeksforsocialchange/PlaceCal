# frozen_string_literal: true

class Components::Breadcrumb < Components::Base
  prop :trail, Array, default: -> { [] }
  prop :site_name, String, default: 'The Community Calendar'

  def view_template(&)
    div(class: 'pc-breadcrumb flex flex-wrap justify-start text-[0.8rem] my-4') do
      div(class: 'flex-[0_1_auto] mr-2 flex items-center gap-1 max-tp:mb-2') do
        span(class: 'max-tp:hidden') do
          link_to(@site_name, '/')
        end
      end
      @trail.each do |link|
        div(class: 'flex-[0_1_auto] mr-2 flex items-center gap-1 max-tp:mb-2 [&_svg]:size-4 [&_svg]:text-base-primary') do
          raw(view_context.icon(:triangle_right, size: nil))
          link_to(link[0], link[1])
        end
      end
      div(class: 'flex-[1_1_auto] flex flex-row gap-4 justify-end mr-0 tp:text-right', &)
    end
  end
end
