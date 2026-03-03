# frozen_string_literal: true

class Views::Admin::Users::ProfileTabPermissions < Views::Admin::Base
  prop :form, _Any, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    current = helpers.current_user

    div(class: 'space-y-6') do
      div(class: 'card bg-base-100 border border-base-300 shadow-sm') do
        div(class: 'card-body p-6') do
          render Components::Admin::SectionHeader.new(
            title: t('admin.users.profile.permissions_title'),
            description: t('admin.users.profile.permissions_description'),
            margin: 4
          )

          render_root_alert if current.root?
          render_permissions_content(current)
        end
      end
    end
  end

  private

  def render_root_alert
    div(role: 'alert', class: 'alert bg-amber-50 border-amber-200 text-amber-800 mb-4') do
      raw icon(:crown, size: '5', css_class: 'text-amber-500')
      span do
        plain 'You are a '
        strong { 'root' }
        plain ' user and can access everything.'
      end
    end
  end

  def render_permissions_content(current) # rubocop:disable Metrics/AbcSize
    if user_has_no_rights?(current)
      render_no_rights_warning
    elsif current.partners.any? || current.neighbourhoods.any? || current.partnership_admin? || current.sites.any?
      render_permissions_grid(current)
    end
  end

  def render_no_rights_warning
    div(role: 'alert', class: 'alert alert-warning no-admin-rights') do
      raw icon(:warning, size: '5')
      span { t('admin.users.profile.no_rights_warning') }
    end
  end

  def render_permissions_grid(current) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4') do
      render_partners_section(current) if current.partners.any?
      render_neighbourhoods_section(current) if current.neighbourhoods.any?
      render_partnerships_section(current) if current.partnership_admin?
      render_sites_section(current) if current.sites.any?
    end
  end

  def render_partners_section(current) # rubocop:disable Metrics/AbcSize
    render_permission_card(
      icon_name: :partner,
      icon_bg: 'bg-emerald-100',
      icon_color: 'text-emerald-600',
      title: t('admin.users.profile.your_partners')
    ) do
      render Components::Admin::ItemBadgeList.new(
        items: current.partners.order(:name),
        icon_name: :partner,
        icon_color: 'bg-emerald-100 text-emerald-600',
        link_path: :edit_admin_partner_path,
        empty_text: t('admin.empty.none_assigned', items: Partner.model_name.human(count: 2).downcase),
        vertical: true
      )
    end
  end

  def render_neighbourhoods_section(current) # rubocop:disable Metrics/AbcSize
    render_permission_card(
      icon_name: :map_pin,
      icon_bg: 'bg-sky-100',
      icon_color: 'text-sky-600',
      title: t('admin.users.profile.your_neighbourhoods')
    ) do
      render Components::Admin::ItemBadgeList.new(
        items: current.neighbourhoods.order(:name),
        icon_name: :map_pin,
        icon_color: 'bg-sky-100 text-sky-600',
        link_path: :edit_admin_neighbourhood_path,
        empty_text: t('admin.empty.none_assigned', items: Neighbourhood.model_name.human(count: 2).downcase),
        vertical: true
      )
    end
  end

  def render_partnerships_section(current) # rubocop:disable Metrics/AbcSize
    render_permission_card(
      icon_name: :partnership,
      icon_bg: 'bg-amber-100',
      icon_color: 'text-amber-700',
      title: t('admin.users.profile.your_partnerships')
    ) do
      render Components::Admin::ItemBadgeList.new(
        items: current.tags.order(:name),
        icon_name: :partnership,
        icon_color: 'bg-amber-100 text-amber-700',
        link_path: :edit_admin_tag_path,
        empty_text: t('admin.empty.none_assigned', items: Partnership.model_name.human(count: 2).downcase),
        vertical: true
      )
    end
  end

  def render_sites_section(current) # rubocop:disable Metrics/AbcSize
    render_permission_card(
      icon_name: :site,
      icon_bg: 'bg-violet-100',
      icon_color: 'text-violet-600',
      title: t('admin.users.profile.your_sites')
    ) do
      render Components::Admin::ItemBadgeList.new(
        items: current.sites.order(:name),
        icon_name: :site,
        icon_color: 'bg-violet-100 text-violet-600',
        link_path: :edit_admin_site_path,
        empty_text: t('admin.empty.none_assigned', items: Site.model_name.human(count: 2).downcase),
        vertical: true
      )
    end
  end

  def render_permission_card(icon_name:, icon_bg:, icon_color:, title:) # rubocop:disable Metrics/AbcSize
    div(class: 'bg-base-200/50 rounded-lg p-4') do
      div(class: 'flex items-center gap-2 mb-3') do
        div(class: "w-8 h-8 rounded-lg #{icon_bg} flex items-center justify-center") do
          raw icon(icon_name, size: '4', css_class: icon_color)
        end
        h4(class: 'font-medium') { title }
      end
      yield
    end
  end
end
