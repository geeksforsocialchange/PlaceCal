# frozen_string_literal: true

class Components::Sites::Meta < Components::Base
  prop :permalink, _Nilable(String), :positional, default: nil
  # The pink underline is for body copy; links in this band underline in the text colour.
  LINK = 'text-foreground underline decoration-current decoration-auto underline-offset-auto skip-ink-auto'

  def after_initialize
    @link_content = nil
  end

  def with_link(&block)
    @link_content = block
    nil
  end

  def view_template
    yield self if block_given?

    div(class: 'meta text-sm leading-normal bg-rules py-8 print:hidden') do
      div(class: 'container-public flex flex-wrap items-baseline gap-x-6') do
        raw(view_context.capture(&@link_content)) if @link_content
        if @permalink
          div(class: 'meta__permalink ms-auto') do
            a(href: "https://placecal.org#{@permalink}", class: LINK) { t('components.meta.permalink') }
          end
        end
      end
    end
  end
end
