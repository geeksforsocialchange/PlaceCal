# frozen_string_literal: true

class Views::Mailers::Join::DemoRequest < Views::Mailers::Base
  prop :demo_request, ::DemoRequest, reader: :private

  def email_content
    field 'Name', demo_request.name
    field 'Email', demo_request.email
    field 'Organisation', demo_request.organisation
    field 'Working for', audience_label
    field 'Message', demo_request.message
  end

  private

  def audience_label
    return if demo_request.audience.blank?

    t("join.audiences.#{demo_request.audience}.title")
  end

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
