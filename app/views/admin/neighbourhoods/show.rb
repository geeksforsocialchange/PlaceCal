# frozen_string_literal: true

class Views::Admin::Neighbourhoods::Show < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  register_value_helper :safe_neighbourhood_name

  prop :neighbourhood, Neighbourhood, reader: :private

  def view_template
    content_for(:title) { safe_neighbourhood_name(neighbourhood) }
    render_header
    render_stats_row
    render_hierarchy_section
    render_bento_grid
  end

  private

  def render_header # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'flex items-center justify-between mb-6') do
      div do
        h1(class: 'text-2xl font-semibold') { safe_neighbourhood_name(neighbourhood) }
        div(class: 'mt-1') do
          render Components::Admin::NeighbourhoodHierarchyBadge.new(
            neighbourhood: neighbourhood, link_each: true, show_icons: true
          )
        end
      end
      div(class: 'text-right') do
        div(class: 'text-sm text-gray-600') { "#{t('admin.labels.id')}: #{neighbourhood.id}" }
        if view_context.current_user.root?
          link_to(edit_admin_neighbourhood_path(neighbourhood),
                  class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white ' \
                         'border-placecal-orange gap-1 mt-2') do
            icon(:edit, size: '3')
            plain t('admin.actions.edit')
          end
        end
      end
    end
  end

  def render_stats_row # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mb-6') do
      render Components::Admin::StatCard.new(
        label: t('admin.neighbourhoods.show.stats.partners'),
        value: neighbourhood.partners.count.to_s, icon: :partner
      )
      render_level_card
      render Components::Admin::StatCard.new(
        label: t('admin.neighbourhoods.show.stats.children'),
        value: neighbourhood.descendants.count.to_s, icon: :arrow_down
      )
      render Components::Admin::StatCard.new(
        label: t('admin.neighbourhoods.show.stats.sites'),
        value: neighbourhood.sites.count.to_s, icon: :site
      )
      render_ons_code_card
      render_ons_dataset_card
    end
  end

  def render_level_card # rubocop:disable Metrics/AbcSize
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-3') do
        div(class: 'flex items-center justify-between') do
          span(class: 'text-xs text-gray-600') { t('admin.neighbourhoods.show.stats.level') }
          level_badge(neighbourhood.level, size: :small)
        end
        div(class: 'text-xl font-bold text-base-content') { neighbourhood.unit&.titleize }
      end
    end
  end

  def render_ons_code_card # rubocop:disable Metrics/AbcSize
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-3') do
        div(class: 'flex items-center justify-between') do
          span(class: 'text-xs text-gray-600') { t('admin.neighbourhoods.show.stats.ons_code') }
          span(class: 'text-xs text-gray-400 font-serif') { "\u00A7" }
        end
        div(class: 'text-lg font-mono font-bold text-base-content') do
          plain neighbourhood.unit_code_value || "\u2014"
        end
      end
    end
  end

  def render_ons_dataset_card # rubocop:disable Metrics/AbcSize
    is_current = !neighbourhood.legacy_neighbourhood?
    div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
      div(class: 'card-body p-3') do
        div(class: 'flex items-center justify-between') do
          span(class: 'text-xs text-gray-600') { t('admin.neighbourhoods.show.stats.ons_dataset') }
          if is_current
            span(class: 'badge badge-xs badge-success') { t('admin.neighbourhoods.show.stats.current') }
          else
            span(class: 'badge badge-xs badge-warning') { t('admin.neighbourhoods.show.stats.legacy') }
          end
        end
        div(class: 'text-lg font-bold text-base-content') do
          plain neighbourhood.release_date&.strftime('%b %Y') || "\u2014"
        end
      end
    end
  end

  def render_hierarchy_section
    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8') do
      render_ancestors_card
      render_children_card
    end
  end

  def render_ancestors_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(
             title: t('admin.neighbourhoods.show.parent_hierarchy'), icon: :arrow_up
           )) do
      ancestors = neighbourhood.ancestors.order(:ancestry)
      if ancestors.any?
        div(class: 'space-y-1') do
          ancestors.reverse_each do |ancestor|
            link_to(admin_neighbourhood_path(ancestor),
                    class: 'flex items-center gap-3 p-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
              level_badge(ancestor.level)
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                            'transition-colors truncate block') { safe_neighbourhood_name(ancestor) }
                span(class: 'text-xs text-gray-600') { ancestor.unit&.titleize }
              end
              icon(:chevron_right, size: '4',
                                   css_class: 'text-gray-400 group-hover:text-placecal-orange transition-colors')
            end
          end
        end
      else
        div(class: 'flex items-center gap-3 py-4 text-gray-500') do
          icon(:globe, size: '6', css_class: 'stroke-[1.5]')
          span(class: 'text-sm') { t('admin.neighbourhoods.show.is_root') }
        end
      end
    end
  end

  def render_children_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render(Components::Admin::Card.new(
             title: t('admin.neighbourhoods.show.child_neighbourhoods'), icon: :arrow_down
           )) do
      children = neighbourhood.children.order(:name)
      if children.any?
        div(class: 'space-y-1 max-h-96 overflow-y-auto') do
          children.each { |child| render_child_row(child) }
        end
        if children.count > 10
          p(class: 'text-xs text-gray-600 mt-3 text-center') do
            plain t('admin.neighbourhoods.show.descendants', count: children.count)
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :neighbourhood, message: t('admin.neighbourhoods.show.no_children'),
          icon_size: '8', padding: 'py-6'
        )
      end
    end
  end

  def render_child_row(child) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    can_view = child.descendants.present? || view_context.current_user.can_view_neighbourhood_by_id?(child.id)
    if can_view
      link_to(admin_neighbourhood_path(child),
              class: 'flex items-center gap-3 p-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
        level_badge(child.level)
        div(class: 'flex-1 min-w-0') do
          span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                      'transition-colors truncate block') { safe_neighbourhood_name(child) }
          span(class: 'text-xs text-gray-600') { child.unit&.titleize }
        end
        span(class: 'badge badge-sm badge-ghost') { child.descendants.count.to_s } if child.descendants.any?
        icon(:chevron_right, size: '4',
                             css_class: 'text-gray-400 group-hover:text-placecal-orange transition-colors')
      end
    else
      div(class: 'flex items-center gap-3 p-2 text-gray-600') do
        level_badge(child.level)
        div(class: 'flex-1 min-w-0') do
          span(class: 'text-sm truncate block') { safe_neighbourhood_name(child) }
          span(class: 'text-xs text-gray-600') { child.unit&.titleize }
        end
      end
    end
  end

  def render_bento_grid
    div(class: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4') do
      render_partners_card
      render_sites_card if view_context.policy(Site).index?
      render_admins_card
    end
  end

  def render_partners_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    all_partners = neighbourhood.partners.sort_by(&:name)
    display_partners = all_partners.first(10)

    render(Components::Admin::Card.new(
             title: Partner.model_name.human(count: 2), icon: :partner,
             header_link: all_partners.count > 10 ? admin_partners_path : nil,
             header_link_text: all_partners.count > 10 ? t('admin.actions.view_all') : nil
           )) do
      if display_partners.any?
        div(class: 'space-y-1') do
          display_partners.each { |partner| render_partner_row(partner) }
        end
        if all_partners.count > 10
          p(class: 'text-xs text-gray-600 mt-3 text-center') do
            plain t('admin.neighbourhoods.show.showing_of_total', shown: 10, total: all_partners.count)
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :partner, message: t('admin.neighbourhoods.show.no_partners'),
          icon_size: '8', padding: 'py-6'
        )
      end
    end
  end

  def render_partner_row(partner) # rubocop:disable Metrics/AbcSize
    if view_context.policy(partner).update?
      link_to(edit_admin_partner_path(partner),
              class: 'flex items-center gap-3 p-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
        div(class: 'w-8 h-8 rounded-lg bg-placecal-orange/10 flex items-center justify-center shrink-0') do
          icon(:partner, size: '4', css_class: 'text-placecal-orange')
        end
        span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                    'transition-colors truncate flex-1') { partner.name }
      end
    else
      div(class: 'flex items-center gap-3 p-2 text-gray-600') do
        div(class: 'w-8 h-8 rounded-lg bg-base-300 flex items-center justify-center shrink-0') do
          icon(:partner, size: '4', css_class: 'text-gray-500')
        end
        span(class: 'text-sm truncate flex-1') { partner.name }
      end
    end
  end

  def render_sites_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    sites = neighbourhood.sites.order(:name)
    render(Components::Admin::Card.new(title: Site.model_name.human(count: 2), icon: :site)) do
      if sites.any?
        div(class: 'space-y-1') do
          sites.each do |site|
            link_to(edit_admin_site_path(site),
                    class: 'flex items-center gap-3 p-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
              div(class: 'w-8 h-8 rounded-lg bg-info/10 flex items-center justify-center shrink-0') do
                icon(:site, size: '4', css_class: 'text-info')
              end
              div(class: 'flex-1 min-w-0') do
                span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                            'transition-colors truncate block') { site.name }
                span(class: 'text-xs text-gray-600') { "#{site.slug}.placecal.org" }
              end
            end
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :site, message: t('admin.neighbourhoods.show.no_sites'),
          icon_size: '8', padding: 'py-6'
        )
      end
    end
  end

  def render_admins_card # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    admins = neighbourhood.users.order(:email)
    render(Components::Admin::Card.new(
             title: t('admin.neighbourhoods.show.neighbourhood_admins'), icon: :users
           )) do
      if admins.any?
        div(class: 'space-y-1') do
          admins.each { |admin_user| render_admin_row(admin_user) }
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :users, message: t('admin.neighbourhoods.show.no_admins'),
          icon_size: '8', padding: 'py-6'
        )
      end
    end
  end

  def render_admin_row(admin_user) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    if view_context.policy(admin_user).update?
      link_to(edit_admin_user_path(admin_user),
              class: 'flex items-center gap-3 p-2 rounded-lg hover:bg-base-200/50 transition-colors group') do
        div(class: 'w-8 h-8 rounded-lg bg-success/10 flex items-center justify-center shrink-0') do
          icon(:user, size: '4', css_class: 'text-success')
        end
        div(class: 'flex-1 min-w-0') do
          span(class: 'text-sm font-medium text-base-content group-hover:text-placecal-orange ' \
                      'transition-colors truncate block') { admin_user.full_name.presence || admin_user.email }
          span(class: 'text-xs text-gray-600') { admin_user.email } if admin_user.full_name.present?
        end
      end
    else
      div(class: 'flex items-center gap-3 p-2 text-gray-600') do
        div(class: 'w-8 h-8 rounded-lg bg-base-300 flex items-center justify-center shrink-0') do
          icon(:user, size: '4', css_class: 'text-gray-500')
        end
        span(class: 'text-sm truncate flex-1') { admin_user.full_name.presence || admin_user.email }
      end
    end
  end
end
