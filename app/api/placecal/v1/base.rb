require 'grape-swagger'

module Placecal
  module V1
    class Base < Grape::API
      mount Placecal::V1::Events
      add_swagger_documentation(
        info: {
          title: "PlaceCal API v1",
          description: "Under heavy development! Authentication will be required soon so don't build anything on this you're not willing to change!"
        },
        api_version: "v1",
        hide_documentation_path: true,
        mount_path: "/api/v1/swagger_doc",
        hide_format: true
      )
    end
  end
end
