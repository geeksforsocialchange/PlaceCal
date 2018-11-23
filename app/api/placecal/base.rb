module Placecal
  class Base < Grape::API
    mount Placecal::V1::Base
  end
end
