# frozen_string_literal: true

class CaseStudyPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::CaseStudy.new(
      partner: "Hulme Community Garden Centre",
      link_url: "/find-placecal",
      logo_src: "https://placekitten.com/200/80",
      image_alt: "Hulme Community Garden Centre events",
      image_src: "https://placekitten.com/800/400",
      partner_url: "/partners/hulme-garden-centre",
      pull_quote: "PlaceCal helped us reach people who never knew we existed.",
      description: [
        "Hulme Community Garden Centre runs weekly sessions for local residents.",
        "Since joining PlaceCal, attendance has increased by 40%.",
        "Their events now appear across three local PlaceCal sites."
      ]
    )
  end
end
