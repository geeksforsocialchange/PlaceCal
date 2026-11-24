# frozen_string_literal: true

# A full-width band holding one section of a join page in the page container.
class Components::Join::Section < Components::Join::Base
  # Each band sets the ink for everything inside it; headings and labels pick it up with tone: :inherit.
  BANDS = {
    page: 'text-foreground',
    salmon: 'bg-secondary text-foreground-darker',
    tint: 'bg-home-background-3 text-foreground-dark',
    green: 'bg-primary text-foreground-darker',
    cream: 'bg-cream text-foreground border-y-2 border-rules'
  }.freeze
  PADDING = { md: 'py-10 lg:py-12', slim: 'py-8' }.freeze

  prop :band, _Union(*BANDS.keys), default: :page
  prop :padding, _Union(*PADDING.keys), default: :md
  prop :attributes, Hash, :**

  def view_template(&)
    section(class: [BANDS[@band], PADDING[@padding]].join(' '), **@attributes) do
      div(class: 'container-public', &)
    end
  end
end
