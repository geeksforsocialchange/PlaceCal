# frozen_string_literal: true

class Views::Mailers::PartnershipBroadcasts::Broadcast < Views::Mailers::Base
  prop :broadcast, PartnershipBroadcast, reader: :private
  prop :preferences_url, String, reader: :private

  def email_content
    broadcast.body.split(/\n{2,}/).each do |paragraph|
      p(style: 'white-space: pre-line;') { paragraph }
    end

    hr
    p(style: 'font-size: 12px; color: #666;') do
      plain t('mailers.partnership_broadcast.footer.why',
              partnership: broadcast.partnership.name,
              sender: broadcast.sender&.full_name.presence || 'PlaceCal')
      plain ' '
      a(href: preferences_url) { t('mailers.partnership_broadcast.footer.preferences') }
      plain '.'
    end
  end
end
