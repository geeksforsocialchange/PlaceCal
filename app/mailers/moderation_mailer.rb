# frozen_string_literal: true

class ModerationMailer < ApplicationMailer
  def hidden_message(users, partner_name, reason_html, mod_email)
    @partner_name = partner_name
    @reason = reason_html
    @mod_email = mod_email

    mail(to: 'support@placecal.org', subject: 'Your partner has been hidden from PlaceCal')
    users.each do |user|
      puts '%' * 80
      puts '%' * 80
      @user = user
      puts @user.full_name
      puts @user
      puts '%' * 80
      mail(to: user.email,  subject: 'Your partner has been hidden from PlaceCal')
    end
  end
end
