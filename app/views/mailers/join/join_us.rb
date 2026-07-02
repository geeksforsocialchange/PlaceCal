# frozen_string_literal: true

class Views::Mailers::Join::JoinUs < Views::Mailers::Base
  prop :join_request, JoinRequest, reader: :private

  def email_content
    field 'Name', join_request.name
    field 'Email', join_request.email
    field 'Phone number', join_request.phone
    field 'Job Title', join_request.job_title
    field 'Organization Name', join_request.job_org
    field 'Area you cover', join_request.area
    field 'A Ring Back', join_request.ringback == '1' ? 'Yes' : 'No'
    field 'More Information', join_request.more_info == '1' ? 'Yes' : 'No'
    field 'Why I Want Placecal', join_request.why
  end

  private

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
