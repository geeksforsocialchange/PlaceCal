# frozen_string_literal: true

class Components::Footer < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :site, _Nilable(::Site), :positional, default: nil

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

  # The footer mirrors the derived site nav (#3368 D6), plus the legal and
  # log-in links the footer has always carried.
  def nav_links
    return directory_nav_links if @site.nil?

    links = [
      [t('navigation.site.home'), root_path],
      [t('navigation.site.events'), events_path],
      [t('navigation.site.partners'), partners_path]
    ]
    links << [t('navigation.site.news'), news_index_path] if @site.news_article_count.positive?
    links += site_page_links
    links << [privacy_label, privacy_path]
    links << [t('navigation.site.terms'), terms_of_use_path]
    links << [t('navigation.site.join'), get_in_touch_path] if @site.contact_email.present?
    links << [t('navigation.site.log_in'), new_user_session_path]
    links
  end

  # When the site publishes its own privacy page, the footer link carries that
  # page's title so it matches the header nav.
  def privacy_label
    @site.pages.published.find_by(slug: 'privacy')&.title.presence || t('navigation.site.privacy')
  end

  # A site's own `privacy` page is served by privacy_path (see Page's
  # OVERRIDABLE_ROUTE_SLUGS), so listing it here too would duplicate the link.
  def site_page_links
    @site.pages.in_nav.reject { |page| page.slug == 'privacy' }
         .map { |page| [page.title, site_page_path(page.slug)] }
  end

  def directory_nav_links
    [
      [t('navigation.site.home'), root_path],
      [t('navigation.site.events'), events_path],
      [t('navigation.site.partners'), partners_path],
      [t('navigation.site.log_in'), new_user_session_path],
      [t('navigation.site.privacy'), privacy_path],
      [t('navigation.site.terms'), terms_of_use_path]
    ]
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
      plain " #{@site.site_admin.phone}"
      br
    end
    strong { 'E:' }
    plain ' '
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
    div(class: 'footer__item footer__impressum', data_nosnippet: true) do
      p do
        plain "#{t('colophon.year', year: Time.zone.today.year)} #{t('colophon.copyright')}"
        br
        plain t('colophon.company')
        br
        plain t('colophon.address')
      end
      p do
        plain 'Build: '
        tag.tt do
          link_to(AppVersion.label(fallback: 'main'), AppVersion.url)
        end
      end
    end
  end
end
