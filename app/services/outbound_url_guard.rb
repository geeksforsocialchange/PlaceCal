# frozen_string_literal: true

# Vets user-supplied URLs before the server fetches them (SSRF prevention).
module OutboundUrlGuard
  class BlockedUrl < StandardError; end

  BLOCKED_RANGES = %w[
    0.0.0.0/8
    10.0.0.0/8
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.0.0.0/24
    192.168.0.0/16
    198.18.0.0/15
    224.0.0.0/4
    240.0.0.0/4
    ::/128
    ::1/128
    fc00::/7
    fe80::/10
    fec0::/10
    ff00::/8
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  module_function

  # Returns the address to connect to, or raises BlockedUrl / SocketError.
  def vet!(url)
    host = host_for(url)
    raise BlockedUrl, url if host.nil?

    addresses = numeric_addresses(host) || resolve(host)
    raise SocketError, "Failed to resolve #{host}" if addresses.empty?
    raise BlockedUrl, url if addresses.any? { |ip| blocked_ip?(ip) }

    # IPv4 first: the connection is pinned to one address, so no fallback if IPv6 is unroutable.
    (addresses.find(&:ipv4?) || addresses.first).to_s
  end

  def resolve(host)
    addresses(host)
  end

  def numeric_addresses(host)
    addresses(host, Socket::AI_NUMERICHOST)
  rescue SocketError
    nil
  end

  def addresses(host, flags = nil)
    Addrinfo.getaddrinfo(host, nil, nil, :STREAM, nil, flags).map { |ai| IPAddr.new(ai.ip_address) }.uniq
  end

  def blocked_ip?(ip)
    ip = ip.native if ip.ipv6?
    BLOCKED_RANGES.any? { |range| range.family == ip.family && range.include?(ip) }
  end

  def host_for(url)
    uri = URI.parse(url.to_s)
    return unless %w[http https].include?(uri.scheme&.downcase)

    uri.hostname.presence
  rescue URI::InvalidURIError
    nil
  end
end
