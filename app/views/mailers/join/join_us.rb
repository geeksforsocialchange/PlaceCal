# frozen_string_literal: true

class Views::Mailers::Join::JoinUs < Views::Mailers::Base
  prop :contact_request, ContactRequest, reader: :private

  def email_content
    %i[name email phone job_title job_org area].each do |attribute|
      field ContactRequest.human_attribute_name(attribute), contact_request.public_send(attribute)
    end
    # ContactRequest casts the checkboxes to booleans, so test truthiness —
    # comparing against the raw '1' param value was always false.
    field ContactRequest.human_attribute_name(:ringback), contact_request.ringback ? 'Yes' : 'No'
    field ContactRequest.human_attribute_name(:more_info), contact_request.more_info ? 'Yes' : 'No'
    field ContactRequest.human_attribute_name(:why), contact_request.why
  end

  private

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
