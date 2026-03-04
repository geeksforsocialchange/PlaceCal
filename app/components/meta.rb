# frozen_string_literal: true

class Components::Meta < Components::Base
  prop :permalink, _Nilable(String), :positional

  def after_initialize
    @link_content = nil
  end

  def with_link(&block)
    @link_content = block
    nil
  end

  def view_template
    yield self if block_given?

    div(class: 'pc-meta bg-base-rules py-8 small') do
      div(class: 'c') do
        raw(view_context.capture(&@link_content)) if @link_content
        if @permalink
          div(class: 'float-right') do
            a(href: "https://placecal.org#{@permalink}") { 'Permalink' }
          end
        end
      end
    end
  end
end
