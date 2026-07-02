# frozen_string_literal: true

class Views::Mailers::Join::JoinUs < Views::Mailers::Base
  prop :contact_request, ContactRequest, reader: :private

  def email_content
    field 'Name', contact_request.name
    field 'Email', contact_request.email
    field 'Phone number', contact_request.phone
    field 'Job Title', contact_request.job_title
    field 'Organization Name', contact_request.job_org
    field 'Area you cover', contact_request.area
    field 'A Ring Back', contact_request.ringback == '1' ? 'Yes' : 'No'
    field 'More Information', contact_request.more_info == '1' ? 'Yes' : 'No'
    field 'Why I Want Placecal', contact_request.why
  end

  private

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
