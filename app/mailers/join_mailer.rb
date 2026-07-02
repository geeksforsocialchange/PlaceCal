# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(join_request)
    mail(to: 'support@placecal.org', subject: 'New Join Request') do |format|
      format.html { render Views::Mailers::Join::JoinUs.new(join_request: join_request) }
    end
  end

  def demo_request(demo_request)
    mail(to: 'support@placecal.org', subject: 'New demo request') do |format|
      format.html { render Views::Mailers::Join::DemoRequest.new(demo_request: demo_request) }
    end
  end
end
