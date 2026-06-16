# frozen_string_literal: true

class Views::Homepage::SocialPrescribers < Views::Homepage::Base
  def view_template
    render_audiences(exclude: :social_prescribers)
  end
end
