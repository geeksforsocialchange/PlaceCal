# frozen_string_literal: true

class Views::Mailers::Moderation::HiddenStaffAlert < Views::Mailers::Moderation::Base
  prop :moderator, User, reader: :private

  def email_content
    div { image_tag(image_url('logo.png'), height: '75') }

    p do
      t('mailers.moderation.hidden_staff_alert.intro', name: partner.name, id: partner.id,
                                                       moderator_email: moderator.email, moderator_id: moderator.id)
    end

    p { '---------------------------' }

    render_hidden_notice
  end
end
