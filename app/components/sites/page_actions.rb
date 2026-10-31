# frozen_string_literal: true

# Secondary links below a page's main content.
class Components::Sites::PageActions < Components::Base
  theme_scope :page_actions,
              parts: {
                root: 'The nav holding the row of links.',
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
      UI::Cluster(as: :ul, gap: @in_meta_band ? :lg : :md, row_gap: (:sm if @in_meta_band), justify: @in_meta_band ? :start : :center) do
        @links.each do |label, href, options|
          li { link_to(label, href, part(:link, **(options || {}), class: @in_meta_band ? Sites::Meta::LINK : 'underline')) }
        end
      end
    end
  end
end
