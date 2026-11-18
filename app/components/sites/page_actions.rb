# frozen_string_literal: true

# Secondary links below a page's main content.
class Components::Sites::PageActions < Components::Base
  theme_scope :page_actions,
              parts: {
                root: 'The nav holding the list of links.',
                list: 'The row of links.',
                link: 'One link. In the meta band (see the variant) it reads as plain text.'
              },
              variants: { root: %i[meta_band] },
              tokens: %i[--color-foreground --color-primary]

  # [label, href, options] triples. `options` (data:, rel:, download:, ...)
  # passes straight through to link_to, alongside the component's own class.
  prop :links, Array, default: -> { [] }
  # Inside Sites::Meta's row, sharing a line with the permalink.
  prop :in_meta_band, _Boolean, default: false

  def view_template
    return if @links.empty?

    nav(**part(:root, variant: (:meta_band if @in_meta_band), aria_label: t('page_actions.label'))) do
      @in_meta_band ? render_band_list : render_row
    end
  end

  private

  def render_row
    UI::Cluster(as: :ul, gap: :md, justify: :center, **part(:list)) do
      @links.each { |label, href, options| li { link_to(label, href, part(:link, **(options || {}), class: 'underline')) } }
    end
  end

  # One link per line on phones; one dotted line from md up
  def render_band_list
    ul(**part(:list, class: 'reset flex flex-col gap-1 md:flex-row md:flex-wrap md:gap-y-1')) do
      @links.each_with_index do |(label, href, options), index|
        li(class: ('md:separator-dot' if index.positive?)) { link_to(label, href, part(:link, **(options || {}), class: Sites::Meta::LINK)) }
      end
    end
  end
end
