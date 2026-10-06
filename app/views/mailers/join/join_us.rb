# frozen_string_literal: true

class Views::Mailers::Join::JoinUs < Views::Mailers::Base
  prop :contact_request, ContactRequest, reader: :private

  def email_content
    %i[name email phone job_title job_org area].each do |attribute|
      field ContactRequest.human_attribute_name(attribute), contact_request.public_send(attribute)
    end
    field ContactRequest.human_attribute_name(:ringback), yes_no(contact_request.ringback)
    field ContactRequest.human_attribute_name(:more_info), yes_no(contact_request.more_info)
    field ContactRequest.human_attribute_name(:why), contact_request.why
  end

  private

  def yes_no(value)
    value ? t('join_mailer.join_us.answer_yes') : t('join_mailer.join_us.answer_no')
  end

  def field(label, value)
    p do
      b { label }
      plain ": #{value}"
    end
  end
end
