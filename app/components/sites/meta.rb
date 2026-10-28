# frozen_string_literal: true

class Components::Sites::Meta < Components::Base
  prop :permalink, _Nilable(String), :positional
  # The page actions follow on the same band (the partner page on built-in themes), so they carry its bottom padding.
  prop :followed_by_actions, _Boolean, default: false

  def after_initialize
    @link_content = nil
  end

  def with_link(&block)
    @link_content = block
    nil
  end

  def view_template
    yield self if block_given?

    div(class: "meta text-sm leading-normal bg-rules #{@followed_by_actions ? 'pt-8' : 'py-8'}") do
      div(class: 'container-public flex flex-wrap items-baseline gap-x-6 gap-y-2') do
        raw(view_context.capture(&@link_content)) if @link_content
        if @permalink
          div(class: 'meta__permalink ms-auto') do
            a(href: "https://placecal.org#{@permalink}") { t('components.meta.permalink') }
          end
        end
      end
    end
  end
end
