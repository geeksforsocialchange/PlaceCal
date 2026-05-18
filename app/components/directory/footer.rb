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
      render_link_column('Browse', [
                           ['Events', :events_path],
                           ['Partners', :partners_path],
                           ['Partnerships', :partnerships_path]
                         ])
      render_link_column('For partners', [
                           ['Get in touch', :get_in_touch_path],
                           ['Admin log in', :new_user_session_path]
                         ])
      render_link_column('About', [
                           ['Our story', :our_story_path],
                           ['Privacy policy', :privacy_path],
                           ['Terms of use', :terms_of_use_path]
                         ])
    end
  end

  def render_brand_column
    div do
      image_tag('home/icons/logo-dark.svg', class: 'h-10 mb-4', alt: 'PlaceCal logo')
      div(class: 'font-serif text-base text-tertiary leading-relaxed') do
        plain 'An open, community-run directory of local events and services near you.'
      end
      div(class: 'mt-3') do
        mail_to('info@placecal.org', 'info@placecal.org', class: 'text-sm font-serif text-foreground no-underline hover:underline hover:decoration-primary')
      end
    end
  end

  def render_link_column(title, links)
    div do
      h4(class: 'allcaps-label text-foreground mb-3') { title }
      ul(class: 'list-none space-y-1') do
        links.each do |label, path_method|
          li do
            link_to(label, send(path_method), class: 'font-serif text-detail text-foreground no-underline hover:underline hover:decoration-primary')
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'container-public mt-6 pt-5 border-t-2 border-rules text-xs text-tertiary font-serif flex justify-between flex-wrap gap-2',
        data_nosnippet: true) do
      span { "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}" }
      span do
        build = ENV['GIT_REV'] ? ENV['GIT_REV'][0, 7] : 'main'
        plain 'Build: '
        link_to(build, "https://github.com/geeksforsocialchange/PlaceCal/commit/#{build}",
                class: 'text-tertiary no-underline hover:underline')
      end
    end
  end
end
