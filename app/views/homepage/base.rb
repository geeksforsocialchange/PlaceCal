# frozen_string_literal: true

# Shared base for the legacy informational homepage pages — placecal.org's
# /our-story, /find-placecal, the audience pages, etc. These pre-date the
# nationwide directory redesign and still rely on the home.scss bundle. The
# layout only links that bundle when a page opts in via content_for(:home_styles),
# which keeps the dark home styling off the directory pages that share the
# same nil-site layout.
class Views::Homepage::Base < Views::Base
  include Views::Homepage::Audiences

  def before_template
    content_for(:home_styles) { 'home' }
    super
  end
end
