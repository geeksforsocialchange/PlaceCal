# frozen_string_literal: true

# == Schema Information
#
# Table name: online_addresses
#
#  id         :bigint           not null, primary key
#  link_type  :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class OnlineAddress < ApplicationRecord
  # ==== Includes / Extends ====
  extend Enumerize

  # ==== Constants ====
  # Hosts the importer treats as direct links, in the order it searches descriptions for them.
  SERVICES = {
    jitsi: { domains: %w[meet.jit.si], kind: :meeting },
    google_meet: { domains: %w[meet.google.com], kind: :meeting },
    zoom: { domains: %w[zoom.us], kind: :meeting },
    teams: { domains: %w[teams.microsoft.com teams.live.com], kind: :meeting },
    webex: { domains: %w[webex.com], kind: :meeting },
    goto_meeting: { domains: %w[gotomeet.me gotomeeting.com], kind: :meeting },
    discord: { domains: %w[discord.gg discord.com], kind: :meeting },
    youtube: { domains: %w[youtube.com youtu.be], kind: :stream },
    twitch: { domains: %w[twitch.tv], kind: :stream },
    vimeo: { domains: %w[vimeo.com], kind: :stream },
    facebook: { domains: %w[facebook.com fb.watch], kind: :stream },
    instagram: { domains: %w[instagram.com], kind: :stream },
    linkedin: { domains: %w[linkedin.com], kind: :stream },
    crowdcast: { domains: %w[crowdcast.io], kind: :stream },
    streamyard: { domains: %w[streamyard.com], kind: :stream },
    hopin: { domains: %w[hopin.com], kind: :meeting }
  }.freeze

  DOMAINS = SERVICES.values.flat_map { it[:domains] }.freeze

  # ==== Enums / Enumerize ====
  enumerize :link_type,
            in: %i[direct indirect],
            default: :indirect
  # link_type -- managed by enumerize, attribute declaration skipped

  # ==== Attributes ====
  attribute :url, :string

  # ==== Associations ====
  has_many :events, dependent: :nullify

  # ==== Class methods ====
  def self.service_for(url)
    host = URI.parse(url.to_s.strip).host&.downcase
    return if host.nil?

    SERVICES.find { |_, service| service[:domains].any? { host == it || host.end_with?(".#{it}") } }&.first
  rescue URI::InvalidURIError
    nil
  end

  # ==== Instance methods ====
  def service = self.class.service_for(url)

  def service_name
    I18n.t("online_address.services.#{service}") if service
  end

  def stream? = service && SERVICES.dig(service, :kind) == :stream
end
