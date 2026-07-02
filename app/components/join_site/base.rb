# frozen_string_literal: true

# Chrome and cards for the join marketing site (join.placecal.org, #3163).
# Named JoinSite rather than Join: a Components::Join module would shadow the
# ::Join form model inside every view that includes the Components kit.
class Components::JoinSite::Base < Components::Base
  private

  # Absolute URL of the apex (the nationwide directory) from the join
  # subdomain, e.g. https://placecal.org or http://lvh.me:3000.
  def apex_url
    "#{request.protocol}#{request.domain}#{request.port_string}"
  end

  def audience_path(key)
    join_audience_path(key.tr('_', '-'))
  end
end
