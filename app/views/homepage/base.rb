# frozen_string_literal: true

# Shared base for the legacy informational homepage pages — /find-placecal
# and the audience pages. These pre-date the nationwide directory redesign
# and still rely on the home.scss bundle; the layout only links that bundle
# when a page opts in via content_for(:home_styles), which keeps the dark
# home styling off the directory pages that share the same nil-site layout.
#
# RETIREMENT PLAN (#3163): every remaining page here is deprecated in routes
# and replaced by the join marketing site — delete this whole section (and
# app/components/homepage) when join.placecal.org launches. This is not the
# directory design system; new apex pages belong in views/directory.
class Views::Homepage::Base < Views::Base
  include Views::Homepage::Audiences

  def before_template
    content_for(:home_styles) { 'home' }
    super
  end
end
