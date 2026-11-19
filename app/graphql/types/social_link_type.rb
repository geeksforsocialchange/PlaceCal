# frozen_string_literal: true

module Types
  class SocialLinkType < Types::BaseObject
    description "A link to the partner's profile on a social network or other website"

    field :url, String,
          null: false,
          description: 'Full URL of the profile'

    field :platform, String,
          null: false,
          description: "The network recognised from the URL: #{[*SocialLink::PLATFORMS.keys, :mastodon].join(', ')}, " \
                       'or link for any other site'

    field :name, String,
          null: false,
          description: "The network's display name, or the site's host for any other site"

    field :handle, String,
          description: 'The account name, such as @name or name.bsky.social, when the URL shows it'

    def platform
      object.platform.to_s
    end
  end
end
