module Placecal
  module V1
    class Events < Grape::API
      version 'v1', using: :path
      format :json
      prefix :api

      RESPONSE_LIMIT = 50

      params do
        optional :partner, type: Integer
        optional :place, type: Integer
        optional :page, type: Integer, default: 0
      end

      resource :events do
        desc 'Return list of events'
        get do
          query = Event.upcoming.sort_by_time
          query = query.includes(:address, :partner)
          query = query.by_partner(params[:partner]) if params[:partner]
          query = query.in_place(params[:place]) if params[:place]
          query = query.offset(params[:page] * RESPONSE_LIMIT)
                       .limit(RESPONSE_LIMIT)
          present query, with: Placecal::Entities::Event
        end
      end
    end
  end
end
