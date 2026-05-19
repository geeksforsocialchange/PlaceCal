# frozen_string_literal: true

class Views::Homepage::SocialPrescribers < Views::Base
  include Views::Homepage::Audiences

  def view_template
    render_audiences(exclude: :social_prescribers)
  end
end
