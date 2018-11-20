module Placecal
  class Base < Grape::API
    mount Placecal::V1::Events
  end
end
