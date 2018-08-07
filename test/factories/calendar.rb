# frozen_string_literal: true

FactoryBot.define do
  factory(:calendar) do
    sequence :name do |n|
      "Zion Centre #{n}"
    end
    sequence :source do |n|
	  "https://outlook.office365.com/owa/calendar/#{n}/calendar.ics"
	end
    strategy 'place'
  end
end
