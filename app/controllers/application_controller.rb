# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # http_basic_authenticate_with name: ENV['AUTHENTICATION_NAME'], password: ENV['AUTHENTICATION_PASSWORD'] if Rails.env.staging?
  before_action :authenticate_by_ip if Rails.env.staging?
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_supporters
  before_action :set_navigation

  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    redirect_to admin_root_path
  end

  # Set the day either using the URL or by today's date
  def set_day
    @today = Date.today
    day = params[:day] || 1
    @current_day =
      if params[:year] && params[:month] && day
        Date.new(params[:year].to_i,
                 params[:month].to_i,
                 params[:day].to_i)
      else
        @today
      end
  end

  def set_sort
    @sort = params[:sort].to_s ? params[:sort] : false
  end

  def filter_events(period, **args)
    site      = args[:site]      || false
    place     = args[:place]     || false
    partner   = args[:partner]   || false
    repeating = args[:repeating] || 'on'

    events = Event.all
    events = events.for_site(site) if site
    events = events.in_place(place) if place
    events = events.by_partner(partner) if partner
    events = events.one_off_events_only if repeating == 'off'
    events = events.one_off_events_first if repeating == 'last'
    events =
      if period == 'week'
        events.find_by_week(@current_day).includes(:place)
      else
        events.find_by_day(@current_day).includes(:place)
      end
    args[:limit] ? events.limit(limit) : events
  end

  def sort_events(events, sort)
    if sort == 'summary'
      [[Time.now, events.sort_by_summary]]
    else
      events.sort_by_time.group_by_day(&:dtstart)
    end
  end

  # Get an object representing the requested site.
  # Note:
  #   The admin sub-site does not have a Site object.
  # Side effects:
  #   If the requested site is invalid then redirect to the home page of the
  #   default site.
  def current_site
    return if request.subdomain == 'admin'

    site_slug =
      if request.subdomain == 'www'
        if request.subdomains.second
          request.subdomains.second
        end
      elsif request.subdomain.present?
        request.subdomain
      end
    site_slug ||= 'default-site'

    site = Site.find_by(slug: site_slug)
    redirect_to( root_url( :subdomain => false ) ) unless site

    site
  end

  def set_primary_neighbourhood
    @primary_neighbourhood = current_site&.primary_neighbourhood
  end

  # Takes an array of places or addresses and returns a sanitized json array
  def generate_points(obj)
    obj.reduce([]) do |arr, o|
      arr <<
        if ([Place, Partner].include? o.class) && (o&.address&.latitude)
          {
            lat: o.address.latitude,
            lon: o.address.longitude,
            name: o.name,
            id: o.id
          }
        elsif o.class == Address
          {
            lat: o.latitude,
            lon: o.longitude
          }
        end
    end
  end

  # Create a calendar from array of events
  def create_calendar(events, title = false)
    cal = Icalendar::Calendar.new
    cal.x_wr_calname = title || 'PlaceCal'
    events.each do |e|
      ical = create_ical_event(e)
      cal.add_event(ical)
    end
    cal
  end

  # TODO: Refactor this to a view or something
  # Convert an event object into an ics listing
  def create_ical_event(e)
    event = Icalendar::Event.new
    event.dtstart = e.dtstart
    event.dtend = e.dtend
    event.summary = e.summary
    event.description = "#{e.description}\n\n<a href='https://placecal.org/events/#{e.id}'>More information about this event on PlaceCal.org</a>"
    event.location = e.location
    event
  end

  def default_update(obj, obj_params)
    respond_to do |format|
      if obj.update(obj_params)
        format.html { redirect_to obj, notice: "#{obj.class} was successfully updated." }
        format.json { render :show, status: :ok, location: obj }
      else
        format.html { render :edit }
        format.json { render json: obj.errors, status: :unprocessable_entity }
      end
    end
  end

  def authenticate_by_ip
    # Is whitelist mode enabled?
    return unless ENV['WHITELIST_MODE']
    # Whitelisted ips are stored as comma separated values in the dokku config
    whitelist = ENV['WHITELISTED_IPS'].split(',')
    return if whitelist.include?(request.remote_ip)
    redirect_to 'https://google.com'
  end

  def set_supporters
    @global_supporters = Supporter.global
  end

  # Shared methods across normal, admin and superadmin
  # Use callbacks to share common setup or constraints between actions.
  def set_partner
    @partner = Partner.friendly.find(params[:id])
  end

  def set_place
    @place = Place.friendly.find(params[:id])
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

  def set_navigation
    @navigation = [
      ['Events', events_path],
      ['Places', places_path],
      ['Partners', partners_path]
    ]
    return unless current_site
    if ['hulme', 'moss-side'].include? current_site.slug
      @navigation << ['Bus', bus_path]
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name email password password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name email password password_confirmation current_password])
  end

  def after_sign_in_path_for(_resource)
    admin_root_url(subdomain: 'admin')
  end
end
