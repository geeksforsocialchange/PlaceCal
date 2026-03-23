# frozen_string_literal: true

# FIXME: `link_to`s and `mail_to`s require `!` (important) on their colour classes to override `app/assets/stylesheets/base/typography.scss`. Remove the `!` when the scss is removed.

class Components::Footer < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :site, _Nilable(::Site), :positional, default: nil

  def view_template
    div(class: 'bg-base-text text-base-background text-[0.9rem] leading-[1.4rem] py-12 [&_p]:my-2 [&_a]:text-base-background [&_a]:border-base-secondary [&_h5]:mt-0 [&_pre]:overflow-hidden') do
      div(class: 'c') do
        div(class: footer_inner_class) { render_footer_content }
      end
    end
  end

  private

  def footer_inner_class
    base = 'pc-footer__inner'
    base += ' pc-footer__inner--nosite' unless @site&.site_admin
    base
  end

  def render_footer_content
    render_logo
    hr(class: 'col-span-full pc-footer__hr--1 w-full border-[3px] border-base-tertiary tl:hidden')
    render_nav
    render_site_enquiries if @site&.site_admin
    render_general_enquiries
    render_site_supporters if @site&.supporters&.any?
    hr(class: 'col-span-full w-full border-[3px] border-base-tertiary')
    render_global_supporters
    render_impressum
  end

  def render_logo
    div(class: 'col-span-full pc-footer__logo self-center [&_img]:max-w-[187px]') do
      if @site&.footer_logo.present?
        image_tag(@site.footer_logo.url) if @site.footer_logo.url
      else
        image_tag('logo-footer.svg')
      end
    end
  end

  def render_nav
    div(class: 'col-span-full pc-footer__nav text-base [&_ul]:list-none [&_ul]:ml-0 [&_ul]:pl-0 [&_li]:inline-block [&_li]:mr-2') do
      h5(class: 'allcaps small') { 'Site Navigation' }
      nav(role: 'navigation') do
        ul do
          li { link_to('Home', root_path, class: 'text-base-background!') }
          li { link_to('Events', events_path, class: 'text-base-background!') }
          li { link_to('Partners', partners_path, class: 'text-base-background!') }
          li { link_to('Log in', new_user_session_path, class: 'text-base-background!') }
          li { link_to('Privacy', privacy_path, class: 'text-base-background!') }
          li { link_to('Terms', terms_of_use_path, class: 'text-base-background!') }
        end
      end
    end
  end

  def render_site_enquiries
    div(class: 'col-span-full pc-footer__enquiries--regional') do
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
    mail_to(@site.site_admin.email, class: 'text-base-background!')
  end

  def render_general_enquiries
    div(class: 'col-span-full pc-footer__enquiries--general') do
      h5(class: 'allcaps small') { 'General Enquiries' }
      p { 'Get in touch!' }
      p do
        strong { 'E:' }
        plain ' '
        mail_to('support@placecal.org', class: 'text-base-background!')
      end
    end
  end

  def render_site_supporters
    hr(class: 'col-span-full w-full border-[3px] border-base-tertiary')
    div(class: 'col-span-full') do
      h5(class: 'allcaps small') { " PlaceCal #{@site.name} Supporters" }
      ul(class: 'p-0 mt-4 grid grid-cols-2 tp:grid-cols-3 tl:grid-cols-6 gap-4 list-none') do
        @site.supporters&.each do |supporter|
          li(class: 'grid items-center justify-items-center [&_img]:max-w-full') do
            link_to(supporter.url, class: 'text-base-background!') { image_tag(supporter.logo.url) }
          end
        end
      end
    end
  end

  def render_global_supporters
    return unless view_context.instance_variable_get(:@global_supporters)

    global_supporters = view_context.instance_variable_get(:@global_supporters)
    div(class: 'col-span-full') do
      h5(class: 'allcaps small') { 'PlaceCal Supporters' }
      ul(class: 'p-0 mt-4 grid grid-cols-2 tp:grid-cols-3 tl:grid-cols-6 gap-4 list-none') do
        global_supporters&.each do |supporter|
          li(class: 'grid items-center justify-items-center [&_img]:max-w-full') do
            link_to(supporter.url, class: 'text-base-background!') { image_tag(supporter.logo.url, alt: supporter.name) }
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'col-span-full mt-12 text-base-tertiary [&_a]:text-base-tertiary [&_a]:decoration-base-tertiary') do
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
          link_to(build, "https://github.com/geeksforsocialchange/PlaceCal/commit/#{build}", class: 'text-base-tertiary!')
        end
      end
    end
  end
end
