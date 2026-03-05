# frozen_string_literal: true

class Views::Mailers::Join::JoinUs < Views::Mailers::Base
  prop :join, Join, reader: :private

  def email_content
    field 'Name', join.name
    field 'Email', join.email
    field 'Phone number', join.phone
    field 'Job Title', join.job_title
    field 'Organization Name', join.job_org
    field 'Area you cover', join.area
    field 'A Ring Back', join.ringback == '1' ? 'Yes' : 'No'
    field 'More Information', join.more_info == '1' ? 'Yes' : 'No'
    field 'Why I Want Placecal', join.why
  end

  private

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
