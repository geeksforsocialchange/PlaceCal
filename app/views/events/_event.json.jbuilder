json.extract! event, :id, 
                     :created_at, 
                     :updated_at, 
                     :summary, 
                     :description, 
                     :dtstart, 
                     :dtend,
                     :repeat_frequency,
                     :place,
                     :partner
json.url event_url(event, format: :json)
