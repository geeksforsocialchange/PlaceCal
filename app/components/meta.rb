# frozen_string_literal: true

class Components::Meta < Components::Base
  prop :permalink, _Any, :positional

  def after_initialize
    @link_content = nil
  end

  def with_link(&block)
    @link_content = block
    nil
  end

  def view_template
    yield self if block_given?

    div(class: 'meta small') do
      div(class: 'c') do
        raw safe(helpers.capture(&@link_content)) if @link_content
        if @permalink
          div(class: 'meta__permalink') do
            a(href: "https://placecal.org#{@permalink}") { 'Permalink' }
          end
        end
      end
    end
  end
end
