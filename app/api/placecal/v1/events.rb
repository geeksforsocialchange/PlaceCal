module Placecal
  module V1
    class Events < Grape::API
      version 'v1', using: :path
      format :json
      prefix :api

      resource :events do
        desc 'Return list of events'
        get do
          events = Event.limit(50)
          present events, with: Placecal::Entities::Event
        end
      end
    end
  end
end
