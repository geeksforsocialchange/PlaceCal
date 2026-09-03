# frozen_string_literal: true

module Admin
  # Serves both the admin dashboard (#home, the admin root) and CRUD for a
  # Site's static content pages (#3368, WP 1.1). The dashboard actions predate
  # the Page model and are exempt from Pundit's verification callbacks.
  class PagesController < Admin::ApplicationController
    DASHBOARD_ACTIONS = %i[home icons].freeze

    skip_after_action :verify_authorized, only: DASHBOARD_ACTIONS
    skip_after_action :verify_policy_scoped, only: DASHBOARD_ACTIONS
    before_action :require_root_user, only: [:icons]
    before_action :set_page, only: %i[edit update destroy]

    def home
      @user = current_user
      @sites = policy_scope([:dashboard, Site]).order(:name)

      partners_scope = policy_scope(Partner)
      calendars_scope = policy_scope(Calendar)

      @partners = partners_scope.order(updated_at: :desc).limit(6)
      @calendars = calendars_scope.order(updated_at: :desc).limit(6)
      @users = policy_scope(User).order(updated_at: :desc).limit(6)

      # Calendar states for action items
      @errored_calendars = calendars_scope.where(calendar_state: :error).order(last_import_at: :desc).limit(5)
      @bad_source_calendars = calendars_scope.where(calendar_state: :bad_source).order(last_import_at: :desc).limit(5)

      # Recent/upcoming events from user's partners (subquery instead of pluck)
      partner_ids_subquery = partners_scope.select(:id)
      @upcoming_events = Event.where(organiser_id: partner_ids_subquery).upcoming.order(:dtstart).limit(8)

      # Stats
      @total_partners = partners_scope.count
      @total_calendars = calendars_scope.count
      @total_events_this_week = Event.where(organiser_id: partner_ids_subquery).where(dtstart: Time.current.all_week).count

      # Calendar state counts - single grouped query instead of 4 separate queries
      state_counts = calendars_scope.group(:calendar_state).count
      @working_calendars_count = state_counts['idle'] || 0
      @processing_calendars_count = (state_counts['in_queue'] || 0) + (state_counts['in_worker'] || 0)
      @errored_calendars_count = state_counts['error'] || 0
      @bad_source_calendars_count = state_counts['bad_source'] || 0

      # User's partnerships (tags they manage)
      @user_partnerships = current_user.partnerships.includes(:partners).order(:name)

      render Views::Admin::Pages::Home.new(
        user: @user,
        sites: @sites,
        partners: @partners,
        calendars: @calendars,
        users: @users,
        errored_calendars: @errored_calendars,
        bad_source_calendars: @bad_source_calendars,
        upcoming_events: @upcoming_events,
        total_partners: @total_partners,
        total_calendars: @total_calendars,
        total_events_this_week: @total_events_this_week,
        working_calendars_count: @working_calendars_count,
        processing_calendars_count: @processing_calendars_count,
        errored_calendars_count: @errored_calendars_count,
        bad_source_calendars_count: @bad_source_calendars_count,
        user_partnerships: @user_partnerships
      )
    end

    def icons
      @icons = SvgIconsHelper::ICONS
      render Views::Admin::Pages::Icons.new(icons: @icons)
    end

    def index
      @pages = policy_scope(Page).includes(:site).order('sites.name': :asc, position: :asc, title: :asc)
      authorize @pages
      render Views::Admin::Pages::Index.new(pages: @pages)
    end

    def new
      @page = Page.new(site: default_site)
      authorize @page
      render Views::Admin::Pages::New.new(page: @page, sites: sites_for_select)
    end

    def edit
      authorize @page
      render Views::Admin::Pages::Edit.new(page: @page, sites: sites_for_select)
    end

    def create
      @page = Page.new(permitted_attributes(Page))
      @page.site ||= submitted_site || default_site
      authorize @page

      if @page.save
        flash[:success] = t('admin.pages.flash.created')
        redirect_to edit_admin_page_path(@page)
      else
        flash.now[:danger] = t('admin.pages.flash.not_created')
        render Views::Admin::Pages::New.new(page: @page, sites: sites_for_select),
               status: :unprocessable_content
      end
    end

    def update
      authorize @page

      attributes = attributes_with_submitted_site(permitted_attributes(@page))

      if attributes.nil?
        flash.now[:danger] = t('admin.pages.flash.site_not_permitted')
        return render Views::Admin::Pages::Edit.new(page: @page, sites: sites_for_select),
                      status: :forbidden
      end

      if @page.update(attributes)
        flash[:success] = t('admin.pages.flash.updated')
        redirect_to edit_admin_page_path(@page)
      else
        flash.now[:danger] = t('admin.pages.flash.not_updated')
        render Views::Admin::Pages::Edit.new(page: @page, sites: sites_for_select),
               status: :unprocessable_content
      end
    end

    def destroy
      authorize @page
      @page.destroy
      flash[:success] = t('admin.pages.flash.deleted')
      redirect_to admin_pages_url
    end

    private

    def set_page
      @page = Page.find(params[:id])
    end

    # Sites the current user may attach a page to. Root and editors see them
    # all; a site admin only their own (SitePolicy::Scope excludes editors, who
    # may still manage every page).
    def sites_for_select
      @sites_for_select ||=
        if current_user.root? || current_user.editor?
          Site.order(:name)
        else
          Site.where(site_admin: current_user).order(:name)
        end
    end

    # Site admins usually only have one site, so preselect it.
    def default_site
      sites_for_select.one? ? sites_for_select.first : nil
    end

    # site_id is not a permitted attribute for site admins, so resolve their
    # submitted choice against the sites they actually administer.
    def submitted_site
      site_id = params.dig(:page, :site_id)
      return nil if site_id.blank?

      sites_for_select.find_by(id: site_id)
    end

    # A site admin who administers several sites sees an editable Site select,
    # but site_id is not a permitted attribute for them, so their choice has to
    # be resolved here against the sites they administer. Returns nil when they
    # asked for a site they do not administer, so #update can refuse the change
    # instead of quietly saving the rest and flashing success.
    def attributes_with_submitted_site(attributes)
      return attributes if policy(@page).permitted_attributes.include?(:site_id)

      requested_id = params.dig(:page, :site_id)
      return attributes if requested_id.blank? || requested_id.to_s == @page.site_id.to_s

      site = sites_for_select.find_by(id: requested_id)
      return nil if site.nil?

      attributes.merge(site_id: site.id)
    end

    def require_root_user
      return if current_user&.root?

      flash[:error] = 'You need to be a root admin to access this page.'
      redirect_to admin_root_path
    end
  end
end
