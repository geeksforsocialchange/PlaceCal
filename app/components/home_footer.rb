# frozen_string_literal: true

class Components::HomeFooter < Components::Base
  include Phlex::Rails::Helpers::MailTo

  def view_template
    div(class: 'footer_home') do
      render_head
      hr(class: 'footer_home__hr')
      render_body
      hr(class: 'footer_home__hr')
      render_foot
    end
  end

  private

  def render_head
    div(class: 'footer_home__head') do
      image_tag('home/icons/logo.svg', class: 'footer_home__logo', alt: 'PlaceCal logo')
      hr(class: 'footer_home__hr footer_home__hr--mobile_only')
      nav do
        ul(class: 'footer_home__nav') do
          li { link_to('Admin log in', new_user_session_path, class: 'footer_home__nav__link') }
          li { link_to('Get PlaceCal', get_in_touch_path, class: 'footer_home__nav__link') }
          li { mail_to('info@placecal.org', 'Email us', class: 'footer_home__nav__link') }
        end
      end
    end
  end

  def render_body
    div(class: 'footer_home__body') do
      h5(class: 'footer_home__body__title') { 'Created by' }

      ul(class: 'footer_home__body__logos') do
        li { link_to('https://gfsc.studio') { image_tag('home/logos/gfsc.svg', alt: 'Geeks For Social Change') } }
        li('aria-hidden': 'true') { image_tag('home/icons/plus.svg', alt: '') }
        li { image_tag('home/logos/phase.svg', alt: 'PHASE: place, health, architecture, space, enviroment') }
      end

      h5(class: 'footer_home__body__title') { 'Sponsored by' }

      ul(class: 'footer_home__body__logos') do
        li { image_tag('home/logos/cityverve.svg', alt: 'Cityverve') }
        li { image_tag('home/logos/nesta.svg', alt: 'Nesta') }
        li { image_tag('home/logos/aal.svg', alt: 'Active Assisted Living') }
        li { image_tag('home/logos/lankley.png', alt: 'lankelly chase') }
      end
    end
  end

  def render_foot
    div(class: 'footer_home__foot') do
      p { "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}" }

      p do
        plain t('colophon.company')
        br
        plain t('colophon.address')
        br
        link_to('Privacy policy', privacy_path, class: 'footer_home__foot__link')
        plain ' | '
        link_to('Terms of use', terms_of_use_path, class: 'footer_home__foot__link')
      end

      p do
        build = ENV['GIT_REV'] ? ENV['GIT_REV'][0, 7] : 'main'
        plain 'Build: '
        tag.tt do
          link_to(build, "https://github.com/geeksforsocialchange/PlaceCal/commit/#{build}", class: 'footer_home__foot__link')
        end
      end
    end
  end
end
