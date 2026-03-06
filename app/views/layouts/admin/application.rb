# frozen_string_literal: true

class Views::Layouts::Admin::Application < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::ImageURL
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::CurrentPage
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::Request
  include Components::Admin::SvgIcons

  def view_template
    doctype
    html(lang: 'en') do
      head do
        title do
          if content_for?(:title)
            "#{content_for(:title)} | PlaceCal Admin"
          else
            'PlaceCal Admin'
          end
        end
        csrf_meta_tags
        stylesheet_link_tag 'admin_tailwind', media: 'all', 'data-turbo-track': 'reload'
        javascript_include_tag 'es-module-shims', async: true
        javascript_importmap_tags
        render_meta
      end

      body(class: 'bg-gray-50') do
        render_topbar
        div(class: 'flex pt-14 min-h-screen') do
          nav(aria_label: 'Main navigation', class: 'hidden md:block w-56 flex-shrink-0 bg-gray-100 border-r border-gray-200') do
            div(class: 'py-4') { render_leftbar }
          end
          main(role: 'main', class: 'flex-1 min-h-screen px-6 py-6') do
            render Components::Admin::Flash.new
            yield
            if Rails.env.development?
              div(class: 'font-mono text-gray-500 mt-8 text-sm') do
                raw view_context.debug(view_context.params)
              end
            end
          end
        end
      end
    end
  end

  private

  def render_meta
    meta(property: 'og:site_name', content: 'PlaceCal Admin')
    link(rel: 'icon', type: 'image/png', href: image_url('favicon.png'))
    link(rel: 'apple-touch-icon', href: image_url('apple-touch-icon.png'))
    meta(name: 'viewport', content: 'width=device-width, initial-scale=1')
    meta(name: 'robots', content: 'noarchive')
  end

  def render_topbar
    nav(aria_label: 'Top bar', class: 'fixed top-0 left-0 right-0 h-14 bg-gray-900 flex items-center justify-between px-4 z-50') do
      # Left zone: Logo
      div(class: 'flex items-center gap-6 min-w-[180px]') do
        link_to admin_root_path, class: 'flex items-center gap-2 font-bold text-lg text-white hover:text-placecal-orange transition-colors' do
          span(class: 'text-placecal-orange') { 'PlaceCal' }
          span(class: 'text-xs font-normal text-gray-400') { t('admin.topbar.admin') }
        end
      end

      # Center zone: Quick actions
      div(class: 'flex items-center gap-1') do
        topbar_quick_action(new_admin_partner_path, Partner) if policy(Partner).new?
        topbar_quick_action(new_admin_calendar_path, Calendar) if policy(Calendar).new?
        topbar_quick_action(new_admin_user_path, User) if policy(User).new?
      end

      # Right zone: User menu
      div(class: 'flex items-center gap-2 justify-end') do
        link_to admin_profile_path, class: 'flex items-center gap-2 px-3 py-1.5 rounded-lg text-gray-400 hover:text-white hover:bg-gray-800/80 transition-colors' do
          if current_user&.avatar.present?
            image_tag current_user.avatar.standard.url, class: 'w-7 h-7 rounded-full object-cover', alt: ''
          else
            span(class: 'w-7 h-7 flex items-center justify-center rounded-full bg-gray-700') do
              icon(:user, size: '4')
            end
          end
          span(class: 'text-sm') { current_user&.email }
          icon(:crown, size: '4', css_class: 'text-amber-400') if current_user&.role == :root
        end
        button_to destroy_user_session_path, method: :delete,
                                             class: 'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-gray-500 hover:text-white hover:bg-gray-800/80 transition-colors',
                                             title: t('admin.topbar.sign_out'),
                                             form: { data: { turbo: 'false' } } do
          icon(:logout, size: '4')
          span(class: 'sr-only') { t('admin.topbar.sign_out') }
        end
      end
    end
  end

  def topbar_quick_action(path, model)
    link_to path, class: 'group flex items-center gap-2 px-3 py-1.5 rounded-full text-gray-400 hover:text-white hover:bg-gray-800/80 transition-all duration-200' do
      span(class: 'w-5 h-5 flex items-center justify-center rounded-full bg-gray-700 group-hover:bg-placecal-orange transition-colors duration-200') do
        icon(:plus, size: '3')
      end
      span(class: 'text-sm font-medium') { t('admin.actions.new_model', model: model.model_name.human) }
    end
  end

  def render_leftbar
    nav(class: 'flex flex-col') do
      leftbar_main_links
      leftbar_content_types
      leftbar_support_links
      leftbar_dev_links
      leftbar_build_info
    end
  end

  def leftbar_main_links
    ul(class: 'space-y-1 px-2') do
      admin_nav_link(t('admin.dashboard.title'), admin_root_path, :home)
    end
  end

  def leftbar_content_types
    leftbar_section(t('admin.leftbar.content_types')) do
      admin_nav_link(human_model_name(Partner, count: 2), admin_partners_path, :partner) if policy(Partner).index?
      admin_nav_link(human_model_name(Calendar, count: 2), admin_calendars_path, :calendar) if policy(Calendar).index?
      admin_nav_link(human_model_name(User, count: 2), admin_users_path, :users) if policy(User).index?
      admin_nav_link(human_model_name(Site, count: 2), admin_sites_path, :site) if policy(Site).index?
      admin_nav_link(human_model_name(Neighbourhood, count: 2), admin_neighbourhoods_path, :neighbourhood) if policy(Neighbourhood).index?
      admin_nav_link(human_model_name(Partnership, count: 2), admin_partnerships_path, :partnership) if policy(Partnership).index?
    end
  end

  def leftbar_support_links
    leftbar_section(t('admin.leftbar.get_support')) do
      admin_nav_link(t('admin.leftbar.handbook'), 'https://handbook.placecal.org/', :book)
      admin_nav_link(t('admin.leftbar.discord'), 'http://discord.gfsc.studio/', :chat)
      admin_nav_link(t('admin.leftbar.report_bug'), 'https://github.com/geeksforsocialchange/PlaceCal/issues/new?assignees=&labels=&template=bug_report.md', :bug)
      li do
        span(class: 'flex items-center gap-2 px-3 py-2 text-sm text-gray-600') do
          icon(:mail, size: '4')
          plain t('contact.email')
        end
      end
    end
  end

  def leftbar_dev_links
    return unless policy(Article).index? || policy(Tag).index? || policy(Collection).index? || policy(Supporter).index?

    leftbar_section(t('admin.leftbar.in_development')) do
      admin_nav_link(human_model_name(Tag, count: 2), admin_tags_path, :tag, root_only: true) if policy(Tag).index?
      admin_nav_link(human_model_name(Article, count: 2), admin_articles_path, :article) if policy(Article).index?
      admin_nav_link(human_model_name(Collection, count: 2), admin_collections_path, :list, root_only: true) if policy(Collection).index?
      admin_nav_link(human_model_name(Supporter, count: 2), admin_supporters_path, :credit_card, root_only: true) if policy(Supporter).index?
      admin_nav_link(t('admin.leftbar.import_status'), admin_jobs_path, :cog, root_only: true) if current_user.root?
    end
  end

  def leftbar_section(heading, &)
    h6(class: 'px-4 mt-6 mb-2 text-xs font-semibold text-gray-600 uppercase tracking-wider') { heading }
    ul(class: 'space-y-1 px-2', &)
  end

  def leftbar_build_info
    div(class: 'px-5 mt-8 text-xs text-gray-600 flex items-center gap-1') do
      icon(:code, size: '3')
      plain "#{t('admin.leftbar.build')}: "
      code(class: 'font-mono') do
        git_rev = ENV.fetch('GIT_REV', nil)
        link_to(
          git_rev ? git_rev[0, 7] : 'dev',
          "https://github.com/geeksforsocialchange/PlaceCal/commit/#{git_rev}",
          class: 'text-placecal-teal-dark underline hover:no-underline'
        )
      end
    end
  end

  def admin_nav_link(name, path, icon_name = nil, root_only: false)
    base_classes = 'flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors'
    active_classes = 'bg-placecal-orange-dark text-white'
    inactive_classes = 'text-gray-700 hover:bg-gray-200'
    klass = current_page?(path) ? "#{base_classes} #{active_classes}" : "#{base_classes} #{inactive_classes}"

    li do
      link_to path, class: klass do
        icon(icon_name.to_sym, size: '4') if icon_name
        span(class: 'flex-1') { name }
        icon(:crown, size: '3', css_class: 'text-amber-500') if root_only
      end
    end
  end

  def human_model_name(klass, count: 1)
    klass.model_name.human(count: count)
  end

  def policy(record)
    view_context.policy(record)
  end

  def current_user
    view_context.current_user
  end

  def t(key, **)
    I18n.t(key, **)
  end
end
