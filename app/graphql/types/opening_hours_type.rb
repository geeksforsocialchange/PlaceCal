module Types
  class OpeningHoursType < Types::BaseObject
    field :day_of_week, String
    field :opens, String
    field :closes, String

    def day_of_week
      object['dayOfWeek'].scan(/\/([^\/]*)$/)
      $1
    end
  end
end


