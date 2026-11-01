# frozen_string_literal: true

class Shared::ContactFormPreview < Lookbook::Preview
  # @label Default
  # @notes The get-in-touch form, with PlaceCal's own email card under it.
  def default
    render Components::Shared::ContactForm.new(contact_request: ContactRequest.new, url: "/get-in-touch")
  end
end
