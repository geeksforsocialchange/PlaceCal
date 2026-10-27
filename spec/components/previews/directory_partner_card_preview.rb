# frozen_string_literal: true

# @display context directory
class DirectoryPartnerCardPreview < Lookbook::Preview
  # @label Grid of cards
  # @notes Two columns, as on the directory partners page. Uses unsaved models.
  def grid
    render CardGrid.new(sample_partners)
  end

  # @label Single card
  def single
    render CardGrid.new(sample_partners.first(1))
  end

  private

  def sample_partners
    [
      ["Ashdale Sports Club", "A sports club in Ashdale with football, netball and swimming sessions, and changing facilities that are open to the whole community.", ["Community Events"]],
      ["Beachfront Repair Cafe", "Free repair sessions in Beachfront that keep things out of landfill. Tea, cake and a friendly fixer for whatever you bring.", ["Community Events"]],
      ["Cliffside Book Club", "A monthly reading group in Cliffside that meets over tea to talk about novels, memoirs and poetry.", ["Arts & Culture", "Education & Learning"]],
      ["Beachfront Community Garden", "Volunteer gardening sessions every week in Beachfront. No experience needed, just turn up in old clothes.", ["Health & Wellbeing", "Community Events"]]
    ].each_with_index.map do |(name, summary, categories), index|
      Partner.new(id: index + 1, name:, slug: name.parameterize, summary:).tap do |partner|
        categories.each { partner.categories.build(name: it) }
      end
    end
  end

  class CardGrid < Phlex::HTML
    def initialize(partners)
      super()
      @partners = partners
    end

    def view_template
      div(style: "align-content: start; color: var(--color-foreground); max-width: 760px; display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); column-gap: 2rem") do
        @partners.each do |partner|
          render Components::Directory::PartnerCard.new(partner:, site: nil, area: "Coastshire › Seaview › Beachfront")
        end
      end
    end
  end
end
