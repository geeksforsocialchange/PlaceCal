# frozen_string_literal: true

class Views::Admin::Pages::Home < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :user, User, reader: :private
  prop :sites, ActiveRecord::Relation, reader: :private
  prop :partners, ActiveRecord::Relation, reader: :private
  prop :calendars, ActiveRecord::Relation, reader: :private
  prop :users, ActiveRecord::Relation, reader: :private
  prop :errored_calendars, ActiveRecord::Relation, reader: :private
  prop :bad_source_calendars, ActiveRecord::Relation, reader: :private
  prop :upcoming_events, ActiveRecord::Relation, reader: :private
  prop :total_partners, Integer, reader: :private
  prop :total_calendars, Integer, reader: :private
  prop :total_events_this_week, Integer, reader: :private
  prop :working_calendars_count, Integer, reader: :private
  prop :processing_calendars_count, Integer, reader: :private
  prop :errored_calendars_count, Integer, reader: :private
  prop :bad_source_calendars_count, Integer, reader: :private
  prop :problem_calendars_count, Integer, reader: :private
  prop :user_partnerships, ActiveRecord::Relation, reader: :private

  register_value_helper :user_has_no_rights?

  def view_template
    content_for(:title) { t('admin.dashboard.title') }
    render_no_rights_alert if user_has_no_rights?(view_context.current_user)
    render_welcome_header
    render_stats_row
    render_bento_grid
  end

  private

  def render_no_rights_alert
    div(role: 'alert', class: 'alert alert-error mb-6') do
      icon(:warning, size: '6', css_class: 'shrink-0')
      div do
        h3(class: 'font-bold') { t('admin.missing_permissions.title') }
        p { t('admin.missing_permissions.message') }
      end
    end
  end

  def render_welcome_header # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    hour = Time.current.hour
    greeting_key = if hour < 12 then 'morning'
                   elsif hour < 17 then 'afternoon'
                   else 'evening'
                   end

    div(class: 'flex flex-wrap items-end justify-between gap-4 mb-6') do
      div do
        h1(class: 'text-2xl font-bold text-base-content') do
          plain t("admin.dashboard.greeting.#{greeting_key}")
          plain ", #{user.first_name}" if user.first_name.present?
        end
        p(class: 'text-gray-600 mt-1') { t('admin.dashboard.subtitle') }
      end
      render_quick_action_buttons
    end
  end

  def render_quick_action_buttons # rubocop:disable Metrics/AbcSize
    div(class: 'flex flex-wrap gap-2') do
      [Partner, Calendar, User].each do |model|
        next unless view_context.policy(model).create?

        link_to(view_context.url_for(controller: model.table_name, action: :new),
                data: { turbo: false },
                class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2') do
          icon(:plus, size: '4')
          plain "New #{model.name.titleize}"
        end
      end
    end
  end

  def render_stats_row # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6') do
      render Components::Admin::StatCard.new(
        label: t('admin.dashboard.stats.partners'), value: total_partners.to_s, icon: :partner
      )
      render_calendars_stat_card
      render Components::Admin::StatCard.new(
        label: t('admin.dashboard.stats.events_this_week'), value: total_events_this_week.to_s, icon: :calendar
      )
      render_handbook_link
    end
  end

  def render_calendars_stat_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::StatCard.new(
             label: t('admin.dashboard.stats.calendars'), value: nil,
             subtitle: t('admin.dashboard.stats.calendars_total', count: total_calendars)
           )) do
      div(class: 'flex items-baseline gap-3') do
        render_calendar_stat_tooltip('working_calendars', working_calendars_count, 'text-success',
                                     t('admin.dashboard.stats.working'))
        render_calendar_stat_tooltip('processing_calendars', processing_calendars_count, 'text-info',
                                     t('admin.dashboard.stats.queue'))
        render_calendar_stat_tooltip('problem_calendars', problem_calendars_count,
                                     problem_calendars_count.positive? ? 'text-error' : 'text-gray-400',
                                     t('admin.dashboard.stats.errors'),
                                     t('admin.dashboard.tooltips.problem_calendars',
                                       errors: errored_calendars_count,
                                       bad_source: bad_source_calendars_count))
      end
    end
  end

  def render_calendar_stat_tooltip(tooltip_key, count, color_class, label_text, tooltip_text = nil)
    tooltip_text ||= t("admin.dashboard.tooltips.#{tooltip_key}")
    div(class: 'tooltip tooltip-bottom', data_tip: tooltip_text) do
      span(class: "text-lg font-bold #{color_class}") { count.to_s }
      span(class: 'text-[10px] text-gray-600 ml-0.5') { label_text }
    end
  end

  def render_handbook_link # rubocop:disable Metrics/AbcSize
    link_to('https://handbook.placecal.org/', target: '_blank',
                                              class: 'card bg-base-100 border border-base-300 shadow-sm ' \
                                                     'hover:border-placecal-orange/30 transition-all group', rel: 'noopener') do
      div(class: 'card-body p-3') do
        div(class: 'flex items-center justify-between') do
          span(class: 'text-xs text-gray-600 group-hover:text-placecal-orange transition-colors') do
            plain t('admin.dashboard.stats.need_help')
          end
          icon(:external_link, size: '4', css_class: 'text-gray-400 group-hover:text-placecal-orange/50 transition-colors')
        end
        div(class: 'flex items-center gap-2 mt-1') do
          icon(:book, size: '5', css_class: 'text-gray-500 group-hover:text-placecal-orange transition-colors')
          span(class: 'text-sm font-medium text-gray-600 group-hover:text-base-content transition-colors') do
            plain t('admin.dashboard.links.handbook')
          end
        end
      end
    end
  end

  def render_bento_grid # rubocop:disable Metrics/AbcSize
    div(class: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4') do
      render_sites_card if sites.any?
      render_action_items_card
      render_upcoming_events_card
      render_updated_partners_card
      render_updated_calendars_card
      render_updated_users_card
      render_partnerships_card if user_partnerships.any?
      render_quick_links_card
    end
  end

  def render_sites_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(
             title: t('admin.dashboard.cards.your_sites'), icon: :site,
             header_link: admin_sites_path, header_link_text: t('admin.actions.view_all')
           )) do
      div(class: 'space-y-2') do
        sites.take(4).each do |site|
          link_to(edit_admin_site_path(site),
                  class: 'flex items-center justify-between gap-3 p-3 rounded-lg border border-base-300 ' \
                         'hover:border-placecal-orange/30 hover:bg-base-200/50 transition-colors group') do
            div(class: 'flex-1 min-w-0') do
              h3(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                        'transition-colors truncate') { site.name }
              p(class: 'text-xs text-gray-600') { "#{site.slug}.placecal.org" }
            end
            div(class: 'text-right flex-shrink-0') do
              span(class: 'text-sm font-semibold text-placecal-orange') { site.events_this_week.to_s }
              span(class: 'text-xs text-gray-600 ml-1') { 'events' }
            end
          end
        end
      end
      if sites.count > 4
        link_to t('admin.dashboard.cards.view_all_sites', count: sites.count), admin_sites_path,
                class: 'text-xs text-placecal-orange hover:text-orange-600 mt-2 block text-center'
      end
    end
  end

  def render_action_items_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(
             title: t('admin.dashboard.cards.action_items'), icon: :clipboard,
             icon_class: problem_calendars_count.positive? ? 'text-error' : 'text-success',
             variant: problem_calendars_count.positive? ? :error : :success
           )) do
      if errored_calendars.any? || bad_source_calendars.any?
        div(class: 'space-y-1') do
          render_calendar_issue_links(errored_calendars.take(5), :warning, 'text-error',
                                      bg_class: 'bg-error/10 hover:bg-error/20', badge_text: 'Error')
          render_calendar_issue_links(bad_source_calendars.take(5), :link, 'text-warning',
                                      bg_class: 'bg-warning/10 hover:bg-warning/20', badge_text: 'Bad URL')
          render_view_all_issues_link
        end
      else
        render_all_healthy
      end
    end
  end

  def render_calendar_issue_links(cals, icon_name, icon_class, bg_class:, badge_text:)
    cals.each do |calendar|
      link_to(edit_admin_calendar_path(calendar),
              class: "flex items-center gap-2 py-2 px-2 rounded-lg #{bg_class} transition-colors group") do
        icon(icon_name, size: '4', css_class: "#{icon_class} flex-shrink-0")
        span(class: 'text-sm truncate flex-1') { calendar.name }
        span(class: "text-xs #{icon_class}") { badge_text }
      end
    end
  end

  def render_view_all_issues_link
    total = errored_calendars.count + bad_source_calendars.count
    return unless total > 10

    link_to(admin_calendars_path(filter: 'problems'),
            class: 'text-xs text-gray-600 hover:text-placecal-orange mt-2 block') do
      plain t('admin.dashboard.cards.view_all_issues', count: total)
    end
  end

  def render_all_healthy
    div(class: 'flex items-center gap-3') do
      icon(:check, size: '8', css_class: 'text-success')
      div do
        p(class: 'font-medium text-green-700') { t('admin.dashboard.cards.all_healthy') }
        p(class: 'text-xs text-gray-600') { t('admin.dashboard.cards.no_issues') }
      end
    end
  end

  def render_upcoming_events_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(title: t('admin.dashboard.cards.upcoming_events'), icon: :event)) do
      if upcoming_events.any?
        div(class: 'space-y-1') do
          upcoming_events.take(6).each do |event|
            div(class: 'flex items-center gap-3 py-2 rounded-lg hover:bg-base-200/50 transition-colors') do
              div(class: 'flex-shrink-0 w-10 text-center') do
                div(class: 'text-[10px] font-medium text-placecal-orange uppercase') { event.dtstart.strftime('%b') }
                div(class: 'text-lg font-bold text-base-content leading-tight') { event.dtstart.strftime('%d') }
              end
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content truncate') { event.summary }
                p(class: 'text-xs text-gray-600 truncate') do
                  plain event.dtstart.strftime('%H:%M')
                  plain " \u00B7 #{event.partner.name}" if event.partner
                end
              end
            end
          end
        end
      else
        render_empty_card(:calendar, t('admin.dashboard.cards.no_upcoming_events'))
      end
    end
  end

  def render_updated_partners_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(title: t('admin.dashboard.cards.updated_partners'), icon: :partner)) do
      if partners.any?
        div(class: 'space-y-1') do
          partners.take(6).each do |partner|
            link_to(edit_admin_partner_path(partner),
                    class: 'flex items-center gap-3 py-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
              render_partner_avatar(partner)
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                            'transition-colors truncate') { partner.name }
                p(class: 'text-xs text-gray-600') { "#{time_ago_in_words(partner.updated_at)} ago" }
              end
            end
          end
        end
      else
        render_empty_card(:partner, t('admin.dashboard.cards.no_partners'))
        link_to t('admin.dashboard.cards.add_first_partner'), new_admin_partner_path,
                class: 'text-xs text-placecal-orange hover:text-orange-600 mt-1'
      end
    end
  end

  def render_partner_avatar(partner)
    if partner.image.url
      image_tag(partner.image.url, class: 'w-9 h-9 rounded-lg object-cover flex-shrink-0')
    else
      div(class: 'w-9 h-9 rounded-lg bg-base-300 flex items-center justify-center flex-shrink-0') do
        icon(:partner, size: '4', css_class: 'text-gray-400 stroke-[1.5]')
      end
    end
  end

  def render_updated_calendars_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(title: t('admin.dashboard.cards.updated_calendars'), icon: :calendar)) do
      if calendars.any?
        div(class: 'space-y-1') do
          calendars.take(6).each do |calendar|
            link_to(edit_admin_calendar_path(calendar),
                    class: 'flex items-center gap-3 py-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
              div(class: 'w-9 h-9 rounded-lg bg-base-300 flex items-center justify-center flex-shrink-0') do
                icon(:calendar, size: '4', css_class: 'text-gray-400 stroke-[1.5]')
              end
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                            'transition-colors truncate') { calendar.name }
                p(class: 'text-xs text-gray-600') { "#{time_ago_in_words(calendar.updated_at)} ago" }
              end
            end
          end
        end
      else
        render_empty_card(:calendar, t('admin.dashboard.cards.no_calendars'))
      end
    end
  end

  def render_updated_users_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(title: t('admin.dashboard.cards.updated_users'), icon: :users)) do
      if users.any?
        div(class: 'space-y-1') do
          users.take(6).each do |u|
            link_to(edit_admin_user_path(u),
                    class: 'flex items-center gap-3 py-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
              div(class: 'w-9 h-9 rounded-lg bg-base-300 flex items-center justify-center flex-shrink-0') do
                icon(:user, size: '4', css_class: 'text-gray-400 stroke-[1.5]')
              end
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                            'transition-colors truncate') { u.full_name.presence || u.email }
                p(class: 'text-xs text-gray-600') { "#{time_ago_in_words(u.updated_at)} ago" }
              end
            end
          end
        end
      else
        render_empty_card(:users, t('admin.dashboard.cards.no_users'))
      end
    end
  end

  def render_partnerships_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(
             title: t('admin.dashboard.cards.your_partnerships'), icon: :partnership
           )) do
      div(class: 'space-y-1') do
        user_partnerships.take(6).each do |partnership|
          link_to(edit_admin_tag_path(partnership),
                  class: 'flex items-center justify-between gap-3 py-2 rounded-lg ' \
                         'hover:bg-base-200/50 transition-colors group') do
            div(class: 'flex-1 min-w-0') do
              span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                          'transition-colors truncate') { partnership.name }
              p(class: 'text-xs text-gray-600') { pluralize(partnership.partners.count, 'partner') }
            end
            icon(:chevron_right, size: '4',
                                 css_class: 'text-gray-400 group-hover:text-placecal-orange transition-colors flex-shrink-0')
          end
        end
      end
      if user_partnerships.count > 6
        link_to t('admin.dashboard.cards.view_all_partnerships', count: user_partnerships.count),
                admin_tags_path(type: 'Partnership'),
                class: 'text-xs text-placecal-orange hover:text-orange-600 mt-3 block text-center'
      end
    end
  end

  def render_quick_links_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(title: t('admin.dashboard.cards.quick_links'), icon: :link)) do
      div(class: 'space-y-1') do
        render_quick_link(admin_calendars_path, :calendar, t('admin.dashboard.links.all_calendars'))
        render_quick_link(admin_partners_path, :partner, t('admin.dashboard.links.all_partners'))
        render_quick_link('https://handbook.placecal.org/', :book, t('admin.dashboard.links.handbook'),
                          external: true)
        render_quick_link('http://discord.gfsc.studio/', :chat, t('admin.dashboard.links.discord'),
                          external: true)
      end
    end
  end

  def render_quick_link(path, icon_name, text, external: false) # rubocop:disable Metrics/AbcSize
    attrs = { class: 'flex items-center gap-3 py-2 rounded-lg hover:bg-base-200/50 transition-colors group' }
    attrs[:target] = '_blank' if external

    link_to(path, **attrs) do
      icon(icon_name, size: '5', css_class: 'text-gray-500 group-hover:text-placecal-orange transition-colors')
      span(class: 'text-sm text-base-content/70 group-hover:text-base-content transition-colors') { text }
      icon(:external_link, size: '3', css_class: 'text-gray-400 ml-auto') if external
    end
  end

  def render_empty_card(icon_name, message)
    div(class: 'flex flex-col items-center justify-center py-6 text-gray-500') do
      icon(icon_name, size: '8', css_class: 'mb-2 stroke-[1.5]')
      p(class: 'text-sm') { message }
    end
  end
end
