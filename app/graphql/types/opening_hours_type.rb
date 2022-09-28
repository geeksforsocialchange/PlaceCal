module Types
  class OpeningHoursType < Types::BaseObject
    description "A period of time that this partner is open for"

    field :day_of_week, String, description: "Monday, Tuesday, Wednesday etc"

    field :opens, String, description: "Hour at which business commences"

    field :closes, String, description: "Hour at which business ceaces"

    def day_of_week
      object["dayOfWeek"].scan(%r{/([^/]*)$})
      $1
    end
  end
end
