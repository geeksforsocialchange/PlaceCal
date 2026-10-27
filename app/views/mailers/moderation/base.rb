# frozen_string_literal: true

class Views::Mailers::Moderation::Base < Views::Mailers::Base
  prop :partner, Partner, reader: :private
  prop :reason, String, reader: :private

  private

  # The partner's copy of the notice; the staff alert repeats it under its own intro.
  def render_hidden_notice
    p { t('mailers.moderation.hidden_message.hidden', name: partner.name, id: partner.id) }

    raw safe(reason.to_s)

    p { raw t('mailers.moderation.hidden_message.support_html', support: view_context.mail_to('support@placecal.org')) }
  end
end
