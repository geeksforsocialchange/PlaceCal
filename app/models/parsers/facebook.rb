module Parsers
  class Facebook

    def initialize(page, last_import_date=nil)
      @page = page
      @last_import_date = last_import_date || Date.today
    end

    def events
      @api = Koala::Facebook::API.new(access_token)
      @events = []

      begin
        fields = ['name', 'description', 'start_time', 'end_time', 'updated_time', 'place']

        #Based on experience Facebook can't decide if the `since` field is based on the event date or
        #the creation date. Play it safe and start from the last import date
        results = @api.get_connections(@page, 'events', { fields: fields, since: @last_import_date.to_time.to_i })

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

    private

    def access_token
      @oauth = Koala::Facebook::OAuth.new(ENV["APP_ID"], ENV["APP_SECRET"])
      @oauth.get_app_access_token
    end
  end
end
