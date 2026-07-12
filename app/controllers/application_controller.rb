# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  layout -> { Views::Layouts::Application }

  # http_basic_authenticate_with name: ENV['AUTHENTICATION_NAME'], password: ENV['AUTHENTICATION_PASSWORD'] if Rails.env.staging?
  before_action :store_user_location!, if: :storable_location?
  before_action :authenticate_by_ip if Rails.env.staging?
  protect_from_forgery with: :exception
  before_action :discard_stale_auth_flash, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_supporters
  before_action :set_navigation
  before_action :set_appsignal_namespace

  include Pundit::Authorization
  include EventFeeds

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found
  rescue_from ActionController::UnknownFormat, with: :not_acceptable
  rescue_from ActionDispatch::Http::MimeNegotiation::InvalidType, with: :not_acceptable
  rescue_from ActionController::BadRequest, with: :bad_request
  rescue_from ActionController::InvalidAuthenticityToken, with: :session_expired

  private

  def set_appsignal_namespace
    Appsignal::Transaction.current.set_namespace('public')
  end

  # Devise sets a persistent flash[:alert] (e.g. "You need to sign in...") when
  # an unauthenticated user is bounced away from /admin. That message is only
  # relevant on the sign-in page it redirects to. If the user instead navigates
  # to a public site page, the flash would otherwise persist and be shown
  # there (see #2144), so drop it.
  #
  # Scoped to the public site: admin pages legitimately surface flash[:alert]
  # (e.g. Admin::PartnersController#user_not_authorized) and Devise controllers,
  # which render the sign-in warning, are excluded by the before_action filter.
  def discard_stale_auth_flash
    return if request.subdomain == Site::ADMIN_SUBDOMAIN

    flash.delete(:alert) if flash[:alert].present?
  end

  def user_not_authorized
    redirect_to admin_root_path
  end

  def resource_not_found
    render Views::Shared::ResourceNotFound.new, status: :not_found
  end

  def not_acceptable
    head :not_acceptable
  end

  def bad_request
    head :bad_request
  end

  def session_expired
    flash[:danger] = 'Your session has expired. Please sign in again.'
    redirect_to new_user_session_path
  end

  # Set the day either using the URL or by today's date.
  # Falls back to today if the URL params don't form a valid date
  # (e.g. month=13, day=32 from crawlers hitting random URLs).
  def set_day
    @today = Date.today
    @current_day =
      if params[:year] && params[:month] && params[:day]
        begin
          Date.new(params[:year].to_i,
                   params[:month].to_i,
                   params[:day].to_i)
        rescue ArgumentError
          @today
        end
      else
        @today
      end
  end

  def set_sort
    @sort = params[:sort].to_s ? params[:sort] : false
  end

  # Get an object representing the requested site.
  # Note:
  #   The admin site does not have a Site object, and neither does the
  #   nationwide directory: an apex (no-subdomain) request resolves to nil.
  # Side effects:
  #   An unmatched subdomain redirects to the apex (the directory).
  def current_site
    return @current_site if defined?(@current_site)

    # Do not return a site for the admin subdomain.
    # The admin subdomain gives a global view of data.
    return @current_site = nil if request.subdomain == Site::ADMIN_SUBDOMAIN

    # The join marketing site has no Site row either.
    return @current_site = nil if join_site_request?

    @current_site = Site.find_by_request(request)

    if @current_site.nil? && request.subdomain.present? &&
       request.subdomain != 'www' && !response.redirect?
      redirect_to(root_url(subdomain: false), allow_other_host: true)
    end

    @current_site
  end

  # @return [Boolean] true when this request is for the nationwide directory:
  #   the apex (no matched site) outside the admin and join subdomains.
  def directory_request?
    current_site.nil? && request.subdomain != Site::ADMIN_SUBDOMAIN && !join_site_request?
  end

  # @return [Boolean] true when this request is for the join marketing site
  #   (join.placecal.org).
  def join_site_request?
    request.subdomain == Site::JOIN_SUBDOMAIN
  end

  def set_primary_neighbourhood
    @primary_neighbourhood = current_site&.primary_neighbourhood
  end

  def authenticate_by_ip
    # Is whitelist mode enabled?
    return unless ENV['WHITELIST_MODE']

    # Whitelisted IPs are stored as comma-separated values in the environment
    whitelist = ENV['WHITELISTED_IPS'].split(',')
    return if whitelist.include?(request.remote_ip)

    redirect_to 'https://google.com'
  end

  def set_supporters
    @global_supporters = Supporter.global
  end

  # Shared methods across whole site
  # Use callbacks to share common setup or constraints between actions.
  def set_partner
    @partner = Partner.friendly.find(params[:id])
  end

  def set_user
    @user = User.find(params[:id])
  end

  def set_calendar
    @calendar = Calendar.find(params[:id])
  end

  def set_site
    @site = current_site
  end

  # News has no directory-wide index; apex requests bounce to the homepage.
  def redirect_from_directory
    redirect_to '/' if directory_request?
  end

  def set_navigation
    return @navigation if @navigation

    @navigation = if directory_request?
                    directory_navigation
                  else
                    sub_site_navigation
                  end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name email password password_confirmation])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i[first_name last_name email password password_confirmation
                                               current_password])
  end

  def storable_location?
    (request.subdomain == Site::ADMIN_SUBDOMAIN) && request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || admin_root_url(subdomain: Site::ADMIN_SUBDOMAIN)
  end

  def directory_navigation
    [
      ['Home', root_path],
      ['Partners', partners_path],
      ['Partnerships', partnerships_path],
      ['Events', events_path]
    ]
  end

  def sub_site_navigation
    [
      ['Home', root_path],
      ['Events', events_path],
      ['Partners', partners_path]
    ]
  end
end
