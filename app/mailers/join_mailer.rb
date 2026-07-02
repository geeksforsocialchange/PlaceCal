# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(contact_request)
    mail(to: 'support@placecal.org', subject: 'New Join Request') do |format|
      format.html { render Views::Mailers::Join::JoinUs.new(contact_request: contact_request) }
    end
  end
end
