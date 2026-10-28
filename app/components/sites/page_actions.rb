# frozen_string_literal: true

# Secondary links below a page's main content; themes restyle it via the .page-actions hooks.
class Components::Sites::PageActions < Components::Base
  # [label, href, options] triples. `options` (data:, rel:, download:, ...)
  # passes straight through to link_to, alongside the component's own class.
  prop :links, Array, default: -> { [] }
  # Continues the meta band above it, on the same inset as its container.
  prop :in_meta_band, _Boolean, default: false

  def view_template
    return if @links.empty?

    nav(class: ['page-actions', ('bg-rules pb-8 text-sm' if @in_meta_band)].compact.join(' '), aria_label: t('page_actions.label')) do
      ul(class: "reset flex flex-wrap items-center gap-4 #{@in_meta_band ? 'container-public justify-start' : 'justify-center'}") do
        @links.each do |label, href, options|
          li { link_to(label, href, (options || {}).merge(class: 'page-actions__link text-foreground underline')) }
        end
      end
    end
  end
end
