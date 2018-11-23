module Placecal
  module V1
    class Events < Grape::API
      include Placecal::V1::Defaults

      resource :events do
        desc "Return list of events, starting from today, in date order. Limited to #{RESPONSE_LIMIT} results."
        params do
          optional :organizer, type: Integer, desc: 'Filter by Organiser based on a PlaceCal Partner ID'
          optional :location, type: Integer, desc: 'Filter by Location based on a PlaceCal Partner ID'
          optional :page, type: Integer,
                          default: 0,
                          desc: "Page number if more than #{RESPONSE_LIMIT} results"
        end
        get do
          query = Event.upcoming.sort_by_time
          query = query.includes(:address, :partner)
          query = query.by_partner(params[:organizer]) if params[:organizer]
          query = query.in_place(params[:location]) if params[:location]
          query = query.offset(params[:page] * RESPONSE_LIMIT)
                       .limit(RESPONSE_LIMIT)
          present query, with: Placecal::Entities::Event
        end

        desc 'Return one event'
        params do
          requires :id, type: Integer, desc: 'ID of the event'
        end
        route_param :id do
          get do
            present Event.find(params[:id]), with: Placecal::Entities::Event
          end
        end
      end
    end
  end
end
