# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # I18n translate helper, theme-aware (PlaceCal::ThemeTranslation), so a theme
  # can override mail copy for its own sites the way it overrides page copy
  # (#3368 D19). The mailer views already resolve `t` through it.
  include PlaceCal::ThemeTranslation

  default from: 'no-reply@placecal.org'
  layout false
  helper MailerHelper
end
