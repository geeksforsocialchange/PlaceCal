# frozen_string_literal: true

# Secondary links below a page's main content; themes restyle it via the .page-actions hooks.
class Components::Sites::PageActions < Components::Base
  # [label, href, options] triples. `options` (data:, rel:, download:, ...)
  # passes straight through to link_to, alongside the component's own class.
  prop :links, Array, default: -> { [] }
  # Inside Sites::Meta's row, sharing a line with the permalink.
  prop :in_meta_band, _Boolean, default: false

  def view_template
    return if @links.empty?

    nav(class: 'page-actions', aria_label: t('page_actions.label')) do
      ul(class: "reset flex flex-wrap items-center #{@in_meta_band ? 'gap-x-6 gap-y-2 justify-start' : 'gap-4 justify-center'}") do
        @links.each do |label, href, options|
          li { link_to(label, href, (options || {}).merge(class: "page-actions__link #{@in_meta_band ? Sites::Meta::LINK : 'text-foreground underline'}")) }
        end
      end
    end
  end
end
