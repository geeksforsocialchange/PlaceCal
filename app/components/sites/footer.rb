# frozen_string_literal: true

class Components::Sites::Footer < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :site, _Nilable(::Site), :positional, default: nil
  # The derived site navigation (SiteNavigation), passed through by the layout.
  prop :navigation, _Nilable(_Array(_Any)), default: nil

  HEADING = 'allcaps text-sm leading-normal mt-0 mb-5'
  # Keeps each contact label on the same line as its value.
  NBSP = "\u00A0"
  HR = 'col-span-full w-full border-3 border-tertiary-light'

  def view_template
    footer(class: 'footer bg-foreground text-background text-detail leading-normal py-12 print:hidden') do
      div(class: 'container-public') do
        div(class: footer_inner_class) { render_footer_content }
      end
    end
  end

  private

  def footer_inner_class
    return 'footer__inner footer__inner--nosite grid gap-4 lg:grid-cols-3' unless @site&.site_admin

    'footer__inner grid gap-4 md:grid-cols-2 lg:grid-cols-3'
  end

  def render_footer_content
    render_logo
    hr(class: "#{HR} lg:hidden")
    render_nav
    render_site_enquiries if @site&.site_admin
    render_general_enquiries
    render_site_supporters if @site&.supporters&.any?
    hr(class: HR)
    render_global_supporters
    render_impressum
  end

  def render_logo
    div(class: 'col-span-full lg:col-span-1 self-center') do
      if @site&.footer_logo.present?
        image_tag(@site.footer_logo.url, alt: @site.name, class: 'max-w-42') if @site.footer_logo.url
      else
        image_tag('logo-footer.svg', alt: t('footer.logo_alt'), class: 'max-w-42')
      end
    end
  end

  def render_nav
    div(class: 'col-span-full lg:col-span-2 text-base') do
      h2(class: HEADING, id: 'footer-nav-heading') { t('footer.site_navigation') }
      # Named, so a screen reader's landmark menu distinguishes this nav from
      # the header's rather than listing "navigation" twice.
      nav(role: 'navigation', aria_labelledby: 'footer-nav-heading') do
        ul(class: 'list-none ml-0 pl-0') do
          nav_links.each do |label, path|
            li(class: 'inline-block mr-2') { active_link_to(label, path, base_css_class: UI::Link.css(tone: :inherit)) }
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
    div(class: 'col-span-full md:col-span-1 lg:col-start-2') do
      h2(class: HEADING) { t('footer.site_enquiries', site: @site.name) }
      p(class: 'my-2') { @site.site_admin.full_name }
      p(class: 'my-2') { render_site_contact_info }
    end
  end

  def render_site_contact_info
    if @site.site_admin.phone&.length&.positive?
      strong { t('footer.phone_label') }
      plain NBSP
      plain @site.site_admin.phone
      br
    end
    strong { t('footer.email_label') }
    plain NBSP
    UI::Link(href: "mailto:#{@site.site_admin.email}", tone: :inherit) { @site.site_admin.email }
  end

  # Without site enquiries, general enquiries takes the regional column too.
  def general_span
    @site&.site_admin ? 'md:col-span-1' : 'lg:col-start-2 lg:col-span-2'
  end

  def render_general_enquiries
    div(class: "col-span-full #{general_span}") do
      h2(class: HEADING) { t('footer.general_enquiries') }
      p(class: 'my-2') { t('footer.get_in_touch') }
      p(class: 'my-2') do
        strong { t('footer.email_label') }
        whitespace
        UI::Link(href: 'mailto:support@placecal.org', tone: :inherit) { 'support@placecal.org' }
      end
    end
  end

  def render_site_supporters
    hr(class: HR)
    render_supporters(t('footer.site_supporters', site: @site.name), @site.supporters)
  end

  def render_global_supporters
    return unless view_context.instance_variable_get(:@global_supporters)

    render_supporters(t('footer.global_supporters'), view_context.instance_variable_get(:@global_supporters))
  end

  def render_supporters(heading, supporters)
    div(class: 'col-span-full') do
      h2(class: HEADING) { heading }
      ul(class: 'grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 list-none p-0 mt-4 mb-0') do
        supporters&.each do |supporter|
          li(class: 'grid items-center justify-items-center') do
            link_to(supporter.url) { image_tag(supporter.logo.url, alt: supporter.name, class: 'max-w-full') }
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'col-span-full mt-12 text-tertiary-light', data_nosnippet: true) do
      Shared::Impressum(logo: false, company_details: true)
    end
  end
end
