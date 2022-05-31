# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # http_basic_authenticate_with name: ENV['AUTHENTICATION_NAME'], password: ENV['AUTHENTICATION_PASSWORD'] if Rails.env.staging?
  before_action :store_user_location!, if: :storable_location?
  before_action :authenticate_by_ip if Rails.env.staging?
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_supporters
  before_action :set_navigation

  include Pundit::Authorization

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
    site             = args[:site]             || false
    place            = args[:place]            || false
    partner          = args[:partner]          || false
    partner_or_place = args[:partner_or_place] || false
    repeating        = args[:repeating]        || 'on'

    events = Event.all

    if site
      events = events.for_site(site)
      events = events.with_tags(site.tags) if site.tags.any?
    end

    events = events.in_place(place) if place
    events = events.by_partner(partner) if partner
    events = events.by_partner_or_place(partner_or_place) if partner_or_place
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
  #   The admin site does not have a Site object.
  # Side effects:
  #   If the requested site is invalid then redirect to the home page of the
  #   default site.
  def current_site
    return @current_site if @current_site

    # Do not return a site for the admin subdomain.
    # The admin subdomain gives a global view of data.
    return if request.subdomain == Site::ADMIN_SUBDOMAIN

    @current_site = Site.find_by_request request

    redirect_to( root_url( :subdomain => false ) ) unless @current_site

    @current_site
  end

  def set_primary_neighbourhood
    @primary_neighbourhood = current_site&.primary_neighbourhood
  end

  # Takes an array of Partners and/or Addresses and returns a sanitized json
  # array suitable for creating map markers. Does not check for duplicates.
  def get_map_markers(locations)
    locations.reduce([]) do |arr, loc|
      marker =
        if (Partner == loc.class) && (loc&.address&.latitude) && loc.service_areas.count == 0
          {
            lat: loc.address.latitude,
            lon: loc.address.longitude,
            name: loc.name,
            id: loc.id
          }
        elsif loc.class == Address
          {
            lat: loc.latitude,
            lon: loc.longitude
          }
        end
      if marker then arr << marker else arr end
    end
  end

  # Takes a reducible collection of events and returns json map markers.
  # Removes duplicate locations.
  def get_map_markers_from_events(events)
    get_map_markers(
      @events.reduce([]) do |arr, e|
        loc = e.place || e.address
        if loc then arr << loc else arr end
      end.uniq
    )
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

  def set_navigation
    return if self.class == MountainView::StyleguideController

    @navigation = if current_site&.default_site?
                    [
                      ['Our story', our_story_path],
                      ['Find your PlaceCal', find_placecal_path],
                      ['Join us', join_path]
                    ]
                  else
                    article_count = if @site
                                      Article
                                        .for_site(@site)
                                        .published
                                        .count
                                    else
                                      0
                                    end
                    items = [
                        ['Events', events_path],
                        # ['Places', places_path],
                        ['Partners', partners_path]
                    ]
                    items << ['News', news_index_path] if article_count > 0
                    items
                  end
  end


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name email password password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name email password password_confirmation current_password])
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
end
