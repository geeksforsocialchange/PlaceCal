# frozen_string_literal: true

class Views::Pages::SocialPrescribers < Views::Base
  include Views::Pages::Audiences

  def view_template
    render_audiences(exclude: :social_prescribers)
  end
end
