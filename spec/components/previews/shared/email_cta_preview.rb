# frozen_string_literal: true

class Shared::EmailCtaPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Shared::EmailCta.new(heading: "Rather just email?", body: "Write to us directly and we'll pick it up from there.",
                                            address: "hello@placecal.example")
  end
end
