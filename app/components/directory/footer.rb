# frozen_string_literal: true

class Components::Directory::Footer < Components::Directory::Base
  def view_template
    Shared::Footer(tagline: t('directory.footer.tagline'), logo_alt: t('directory.footer.placecal_logo_alt'), columns:) do
      div(class: 'mt-3') do
        UI::Link(href: 'mailto:support@placecal.org', variant: :quiet, class: 'text-sm font-serif') { 'support@placecal.org' }
      end
    end
  end

  private

  def columns
    [
      [t('directory.footer.browse'), [
        [t('directory.footer.events'), events_path],
        [t('directory.footer.partners'), partners_path],
        [t('directory.footer.partnerships'), partnerships_path]
      ]],
      [t('directory.footer.for_partners'), [
        [t('directory.footer.get_in_touch'), get_in_touch_path],
        [t('directory.footer.discord'), 'http://discord.gfsc.studio/'],
        [t('directory.footer.admin_log_in'), new_user_session_path]
      ]],
      [t('directory.footer.about'), [
        [t('directory.footer.our_story'), our_story_path],
        [t('directory.footer.for_ai_assistants'), '/mcp'],
        [t('directory.footer.privacy_policy'), privacy_path],
        [t('directory.footer.terms_of_use'), terms_of_use_path]
      ]]
    ]
  end
end
