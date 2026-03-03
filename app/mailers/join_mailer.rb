# frozen_string_literal: true

class JoinMailer < ApplicationMailer
  def join_us(join)
    mail(to: 'support@placecal.org', subject: 'New Join Request') do |format|
      format.html { render Views::Mailers::Join::JoinUs.new(join: join) }
    end
  end
end
