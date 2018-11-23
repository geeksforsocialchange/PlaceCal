require 'grape-swagger'

module API
  class Base < Grape::API
    mount API::V1::Events
  end
end
