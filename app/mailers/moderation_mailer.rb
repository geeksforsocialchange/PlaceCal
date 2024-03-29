# frozen_string_literal: true

class ModerationMailer < ApplicationMailer
  def hidden_message(user, partner)
    @reason = partner.hidden_reason_html
    @partner = partner
    @user = user

    mail(to: @user.email,  subject: 'Your partner has been hidden from PlaceCal')
  end

  def hidden_staff_alert(partner)
    @partner = partner
    @reason = partner.hidden_reason_html
    @moderator = User.find(partner.hidden_blame_id)

    mail(to: 'support@placecal.org', subject: 'A partner has been hidden from PlaceCal')
  end
end
