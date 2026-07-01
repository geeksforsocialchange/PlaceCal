# frozen_string_literal: true

# Preview at http://lvh.me:3000/rails/mailers/partner_verification_mailer
class PartnerVerificationMailerPreview < ActionMailer::Preview
  def invite
    partner = Partner.new(id: 1, name: "Dalston Community Cafe")
    partner.define_singleton_method(:new_record?) { false }
    invited_by = User.new(first_name: "Sam", last_name: "Organiser")

    PartnerVerificationMailer.invite(partner, email: "cafe@example.com", invited_by: invited_by)
  end
end
