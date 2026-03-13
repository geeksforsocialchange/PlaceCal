# frozen_string_literal: true

class Components::HomeFooter < Components::Base
  include Phlex::Rails::Helpers::MailTo

  def view_template
    div(class: 'text-base-background py-12 px-8') do
      render_head
      hr(class: 'border-base-tertiary border-t-[3px] my-4')
      render_body
      hr(class: 'border-base-tertiary border-t-[3px] my-4')
      render_foot
    end
  end

  private

  def render_head
    div(class: 'flex flex-col items-center tp:flex-row tp:flex-wrap tp:justify-between') do
      image_tag('home/icons/logo.svg', class: 'max-w-40', alt: 'PlaceCal logo')
      hr(class: 'border-base-tertiary border-t-[3px] my-4 w-full tp:hidden')
      nav do
        ul(class: 'flex flex-col items-center list-none p-0 tp:flex-row tp:flex-wrap tp:gap-8') do
          li { link_to('Admin log in', new_user_session_path, class: 'text-base-background font-semibold no-underline w-max hover:text-base-secondary hover:border-b-[3px] hover:border-base-background') }
          li { link_to('Get PlaceCal', get_in_touch_path, class: 'text-base-background font-semibold no-underline w-max hover:text-base-secondary hover:border-b-[3px] hover:border-base-background') }
          li { mail_to('info@placecal.org', 'Email us', class: 'text-base-background font-semibold no-underline w-max hover:text-base-secondary hover:border-b-[3px] hover:border-base-background') }
        end
      end
    end
  end

  def render_body
    div(class: 'flex flex-col items-center') do
      h5(class: 'text-[1.35rem] text-base-secondary font-serif mb-3 mt-4') { 'Created by' }

      ul(class: 'flex flex-wrap items-center justify-center list-none p-0 [&_svg[data-icon-name="home_plus"]]:text-base-secondary [&_svg[data-icon-name="home_plus"]]:size-[0.9rem]') do
        li { link_to('https://gfsc.studio') { image_tag('home/logos/gfsc.svg', alt: 'Geeks For Social Change') } }
        li('aria-hidden': 'true') { raw(view_context.icon(:home_plus, size: '0')) }
        li { image_tag('home/logos/phase.svg', alt: 'PHASE: place, health, architecture, space, enviroment') }
      end

      h5(class: 'text-[1.35rem] text-base-secondary font-serif mb-3 mt-4') { 'Sponsored by' }

      ul(class: 'flex flex-wrap items-center justify-center list-none p-0') do
        li { image_tag('home/logos/cityverve.svg', alt: 'Cityverve') }
        li { image_tag('home/logos/nesta.svg', alt: 'Nesta') }
        li { image_tag('home/logos/aal.svg', alt: 'Active Assisted Living') }
        li { image_tag('home/logos/lankley.png', alt: 'lankelly chase') }
      end
    end
  end

  def render_foot
    div(class: 'flex flex-col items-center text-[0.66rem] text-center') do
      p { "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}" }

      p do
        plain t('colophon.company')
        br
        plain t('colophon.address')
        br
        link_to('Privacy policy', privacy_path, class: 'text-base-background underline decoration-base-background hover:text-base-secondary')
        plain ' | '
        link_to('Terms of use', terms_of_use_path, class: 'text-base-background underline decoration-base-background hover:text-base-secondary')
      end

      p do
        build = ENV['GIT_REV'] ? ENV['GIT_REV'][0, 7] : 'main'
        plain 'Build: '
        tag.tt do
          link_to(build, "https://github.com/geeksforsocialchange/PlaceCal/commit/#{build}", class: 'text-base-background underline decoration-base-background hover:text-base-secondary')
        end
      end
    end
  end
end
