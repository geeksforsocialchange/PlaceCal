# frozen_string_literal: true

# @display context directory
# @display padding false
class Directory::PageHeroPreview < Lookbook::Preview
  # @label With breadcrumb
  def default
    render Components::Directory::PageHero.new(title: "Privacy policy", breadcrumb_label: "Privacy")
  end

  # @label Kicker and subtitle
  def kicker_and_subtitle
    render Components::Directory::PageHero.new(title: "Partners", kicker: "Directory",
                                               subtitle: "Every group and venue publishing events on PlaceCal.")
  end
end
