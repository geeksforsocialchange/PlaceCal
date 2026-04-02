# frozen_string_literal: true

class Components::Footer < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :site, _Nilable(::Site), :positional, default: nil

  def view_template
    footer(class: 'footer') do
      div(class: 'c') do
        div(class: footer_inner_class) { render_footer_content }
      end
    end
  end

  private

  def footer_inner_class
    "footer__inner #{'footer__inner--nosite' unless @site&.site_admin}".strip
  end

  def render_footer_content
    render_logo
    hr(class: 'footer__item footer__hr footer__hr--1')
    render_nav
    render_site_enquiries if @site&.site_admin
    render_general_enquiries
    render_site_supporters if @site&.supporters&.any?
    hr(class: 'footer__item footer__hr')
    render_global_supporters
    render_impressum
  end

  def render_logo
    div(class: 'footer__item footer__logo') do
      if @site&.footer_logo.present?
        image_tag(@site.footer_logo.url) if @site.footer_logo.url
      else
        image_tag('logo-footer.svg')
      end
    end
  end

  def render_nav
    div(class: 'footer__item footer__nav') do
      h5(class: 'allcaps small') { 'Site Navigation' }
      nav(role: 'navigation') do
        ul do
          li { active_link_to('Home', root_path) }
          li { active_link_to('Events', events_path) }
          li { active_link_to('Partners', partners_path) }
          li { active_link_to('Log in', new_user_session_path) }
          li { active_link_to('Privacy', privacy_path) }
          li { active_link_to('Terms', terms_of_use_path) }
        end
      end
    end
  end

  def render_site_enquiries
    div(class: 'footer__item footer__enquiries footer__enquiries--regional') do
      h5(class: 'allcaps small') { "#{@site.name} Enquiries" }
      p { @site.site_admin.full_name }
      p { render_site_contact_info }
    end
  end

  def render_site_contact_info
    if @site.site_admin.phone&.length&.positive?
      strong { 'T:' }
      plain " #{@site.site_admin.phone}"
      br
    end
    strong { 'E:' }
    plain ' '
    mail_to(@site.site_admin.email)
  end

  def render_general_enquiries
    div(class: 'footer__item footer__enquiries footer__enquiries--general') do
      h5(class: 'allcaps small') { 'General Enquiries' }
      p { 'Get in touch!' }
      p do
        strong { 'E:' }
        plain ' '
        mail_to('support@placecal.org')
      end
    end
  end

  def render_site_supporters
    hr(class: 'footer__item footer__hr')
    div(class: 'footer__item footer__supporters') do
      h5(class: 'allcaps small') { " PlaceCal #{@site.name} Supporters" }
      ul do
        @site.supporters&.each do |supporter|
          li(class: "footer__supporter footer__supporter--#{supporter.name.parameterize}") do
            link_to(supporter.url) { image_tag(supporter.logo.url) }
          end
        end
      end
    end
  end

  def render_global_supporters
    return unless view_context.instance_variable_get(:@global_supporters)

    global_supporters = view_context.instance_variable_get(:@global_supporters)
    div(class: 'footer__item footer__supporters') do
      h5(class: 'allcaps small') { 'PlaceCal Supporters' }
      ul do
        global_supporters&.each do |supporter|
          li(class: "footer__supporter footer__supporter--#{supporter.name.parameterize}") do
            link_to(supporter.url) { image_tag(supporter.logo.url, alt: supporter.name) }
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'footer__item footer__impressum') do
      p do
        plain "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}"
        br
        plain t('colophon.company')
        br
        plain t('colophon.address')
      end
      p do
        build = ENV['GIT_REV'] ? ENV['GIT_REV'][0, 7] : 'main'
        plain 'Build: '
        tag.tt do
          link_to(build, "https://github.com/geeksforsocialchange/PlaceCal/commit/#{build}")
        end
      end
    end
  end
end
