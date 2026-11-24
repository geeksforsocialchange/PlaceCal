# frozen_string_literal: true

# Shared by join components and pages, which link to the directory on the apex.
module Components::Join::ApexUrl
  private

  # Absolute URL of the apex (the nationwide directory) from the join
  # subdomain, e.g. https://placecal.org or http://lvh.me:3000.
  def apex_url
    "#{request.protocol}#{request.domain}#{request.port_string}"
  end
end
