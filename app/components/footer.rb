# frozen_string_literal: true

class Components::Footer < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :site, _Nilable(::Site), :positional, default: nil
  # The derived site navigation (SiteNavigation), passed through by the layout.
  prop :navigation, _Nilable(_Array(_Any)), default: nil

  def view_template
    footer(class: 'footer') do
      div(class: 'container-public') do
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
      h5(class: 'allcaps small') { t('footer.site_navigation') }
      nav(role: 'navigation') do
        ul do
          nav_links.each do |label, path|
            li { active_link_to(label, path) }
          end
        end
      end
    end
  end

  # The footer shows the same derived site nav as the header (#3368 D6), so the
  # region param, the news link, the theme's pages and its nav_join rule all
  # follow from one place, plus the legal and log-in links the footer has
  # always carried. A theme that registers its own `privacy` page arrives with
  # the derived links, so the fixed privacy link is not added twice.
  #
  # Rendered without a derived nav (previews and component specs; the layout
  # always passes one) it falls back to the three links every site nav opens
  # with, so the footer is never empty.
  def nav_links
    links = Array(@navigation).presence&.dup || core_nav_links
    links << [t('navigation.site.privacy'), privacy_path] unless links.any? { |(_label, path)| path == privacy_path }
    links << [t('navigation.site.terms'), terms_of_use_path]
    links << [t('navigation.site.log_in'), new_user_session_path]
    links
  end

  def core_nav_links
    [
      [t('navigation.site.home'), root_path],
      [t('navigation.site.events'), events_path],
      [t('navigation.site.partners'), partners_path]
    ]
  end

  def render_site_enquiries
    div(class: 'footer__item footer__enquiries footer__enquiries--regional') do
      h5(class: 'allcaps small') { t('footer.site_enquiries', site: @site.name) }
      p { @site.site_admin.full_name }
      p { render_site_contact_info }
    end
  end

  def render_site_contact_info
    if @site.site_admin.phone&.length&.positive?
      strong { t('footer.phone_label') }
      plain " #{@site.site_admin.phone}"
      br
    end
    strong { t('footer.email_label') }
    plain ' '
    mail_to(@site.site_admin.email)
  end

  def render_general_enquiries
    div(class: 'footer__item footer__enquiries footer__enquiries--general') do
      h5(class: 'allcaps small') { t('footer.general_enquiries') }
      p { t('footer.get_in_touch') }
      p do
        strong { t('footer.email_label') }
        plain ' '
        mail_to('support@placecal.org')
      end
    end
  end

  def render_site_supporters
    hr(class: 'footer__item footer__hr')
    div(class: 'footer__item footer__supporters') do
      h5(class: 'allcaps small') { t('footer.site_supporters', site: @site.name) }
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
      h5(class: 'allcaps small') { t('footer.global_supporters') }
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
    div(class: 'footer__item footer__impressum', data_nosnippet: true) do
      p do
        plain "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}"
        br
        plain t('colophon.company')
        br
        plain t('colophon.address')
      end
      p do
        plain t('footer.build')
        tag.tt do
          link_to(AppVersion.label(fallback: 'main'), AppVersion.url)
        end
      end
    end
  end
end
