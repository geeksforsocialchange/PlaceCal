# frozen_string_literal: true

class Components::Directory::Footer < Components::Directory::Base
  include Phlex::Rails::Helpers::MailTo

  def view_template
    footer(class: 'bg-home-background border-t-[5px] border-rules mt-16 pt-10 pb-6') do
      render_grid
      render_impressum
    end
  end

  private

  def render_grid
    div(class: 'container-public grid grid-cols-1 md:grid-cols-[1.4fr_1fr_1fr_1fr] gap-8') do
      render_brand_column
      render_link_column(t('directory.footer.browse'), [
                           [t('directory.footer.events'), :events_path],
                           [t('directory.footer.partners'), :partners_path],
                           [t('directory.footer.partnerships'), :partnerships_path]
                         ])
      render_link_column(t('directory.footer.for_partners'), [
                           [t('directory.footer.get_in_touch'), :get_in_touch_path],
                           [t('directory.footer.discord'), 'http://discord.gfsc.studio/'],
                           [t('directory.footer.admin_log_in'), :new_user_session_path]
                         ])
      render_link_column(t('directory.footer.about'), [
                           [t('directory.footer.our_story'), :our_story_path],
                           [t('directory.footer.privacy_policy'), :privacy_path],
                           [t('directory.footer.terms_of_use'), :terms_of_use_path]
                         ])
    end
  end

  def render_brand_column
    div do
      image_tag('home/icons/logo-dark.svg', class: 'h-10 mb-4', alt: t('directory.footer.placecal_logo_alt'), width: 127, height: 40)
      div(class: 'font-serif text-base text-tertiary leading-relaxed') do
        plain t('directory.footer.tagline')
      end
      div(class: 'mt-3') do
        mail_to('support@placecal.org', 'support@placecal.org', class: 'text-sm font-serif text-foreground no-underline hover:underline hover:decoration-primary')
      end
    end
  end

  def render_link_column(title, links)
    div do
      h2(class: 'allcaps-label text-foreground mb-3') { title }
      ul(class: 'list-none space-y-1') do
        links.each do |label, target|
          li do
            href = target.is_a?(Symbol) ? send(target) : target
            link_to(label, href, class: 'font-serif text-detail text-foreground no-underline hover:underline hover:decoration-primary')
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'container-public mt-6 pt-5 border-t-2 border-rules text-xs text-tertiary font-serif [&_p]:my-1',
        data_nosnippet: true) do
      Impressum()
    end
  end
end
