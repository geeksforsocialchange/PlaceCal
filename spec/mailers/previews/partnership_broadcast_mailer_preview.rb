# frozen_string_literal: true

# Preview at http://lvh.me:3000/rails/mailers/partnership_broadcast_mailer
class PartnershipBroadcastMailerPreview < ActionMailer::Preview
  def broadcast
    partnership = Partnership.new(id: 1, name: "Millbrook Together")
    sender = User.new(id: 2, first_name: "Sam", last_name: "Organiser", email: "sam@example.com")
    broadcast = PartnershipBroadcast.new(
      partnership: partnership, sender: sender,
      subject: "Winter network meetup",
      body: "Hello all,\n\nOur next network meetup is on the 12th at the community hall.\n\nSee you there!"
    )

    user = User.new(id: 1, email: "recipient@example.com")
    user.define_singleton_method(:new_record?) { false }

    PartnershipBroadcastMailer.broadcast(user, broadcast)
  end
end
