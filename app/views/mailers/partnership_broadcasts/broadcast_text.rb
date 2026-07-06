# frozen_string_literal: true

class Views::Mailers::PartnershipBroadcasts::BroadcastText < Views::TextBase
  prop :broadcast, PartnershipBroadcast, reader: :private
  prop :preferences_url, String, reader: :private

  def text_content
    footer_why = t('mailers.partnership_broadcast.footer.why',
                   partnership: broadcast.partnership.name,
                   sender: broadcast.sender&.full_name.presence || 'PlaceCal')

    "#{broadcast.body}\n\n--\n#{footer_why}\n" \
      "#{t('mailers.partnership_broadcast.footer.preferences')}: #{preferences_url}"
  end
end
