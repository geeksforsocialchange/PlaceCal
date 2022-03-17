module Types
  class OpeningHoursType < Types::BaseObject
    description 'The open hours within a specific weekday'

    field :day_of_week, String,
      description: 'Monday, Tuesday, Wednesday etc'

    field :opens, String,
      description: 'Hour at which business commences'

    field :closes, String,
      description: 'Hour at which business ceaces'

    def day_of_week
      object['dayOfWeek'].scan(/\/([^\/]*)$/)
      $1
    end
  end
end


