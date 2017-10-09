module Parsers
  class Facebook

    def initialize(page, params={})
      @page = page
      @from = params[:from] || Date.current.beginning_of_day
    end

    def events
      @events = []

      begin
        fields = ['name', 'description', 'start_time', 'end_time', 'updated_time', 'place', 'event_times']
        results = facebook_api.get_connections(@page, 'events', { fields: fields, since: @from.to_time.to_i, until: Calendar::IMPORT_UP_TO.to_time.to_i })

        loop do
          @events += results
          results = results.next_page
          break if results.blank?
        end

      rescue Koala::Facebook::APIError => e
        Rails.logger.debug e
      end

      @events.map { |event| Events::FacebookEvent.new(event) }
    end

    def find_by_uid(uids)
      facebook_api.get_objects(uids)
    end

    private

    def facebook_api
       Koala::Facebook::API.new(access_token)
    end

    def access_token
      @oauth = Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_APP_SECRET"])
      @oauth.get_app_access_token
    end
  end
end
