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

  INET_ATON_PART = /\A(?:0x\h+|0[0-7]*|[1-9]\d*)\z/i

  module_function

  # Returns the address to connect to, or raises BlockedUrl / SocketError.
  def vet!(url)
    host = host_for(url)
    raise BlockedUrl, url if host.nil? || local_hostname?(host)

    addresses = [literal_address(host)].compact.presence || resolve(host)
    raise SocketError, "Failed to resolve #{host}" if addresses.empty?
    raise BlockedUrl, url if addresses.any? { |ip| blocked_ip?(ip) }

    # IPv4 first: the connection is pinned to one address, so no fallback if IPv6 is unroutable.
    (addresses.find(&:ipv4?) || addresses.first).to_s
  end

  # Check without DNS, for cheap model validation.
  def blocked_literal?(url)
    host = host_for(url.to_s.sub(%r{\Awebcal://}i, 'https://'))
    return false if host.nil?
    return true if local_hostname?(host)

    ip = literal_address(host)
    ip.present? && blocked_ip?(ip)
  end

  def resolve(host)
    Addrinfo.getaddrinfo(host, nil, nil, :STREAM).map { |ai| IPAddr.new(ai.ip_address) }.uniq
  end

  def blocked_ip?(ip)
    ip = ip.native if ip.ipv6?
    BLOCKED_RANGES.any? { |range| range.family == ip.family && range.include?(ip) }
  end

  def host_for(url)
    uri = URI.parse(url.to_s)
    return unless %w[http https].include?(uri.scheme&.downcase)

    uri.hostname&.downcase&.delete_suffix('.').presence
  rescue URI::InvalidURIError
    nil
  end

  def local_hostname?(host)
    host == 'localhost' || host.end_with?('.localhost')
  end

  # Also accepts the shorthand, octal and hex IPv4 forms the system resolver does.
  def literal_address(host)
    IPAddr.new(host)
  rescue IPAddr::InvalidAddressError
    inet_aton(host)
  end

  def inet_aton(host)
    parts = host.split('.', -1)
    return unless parts.size.between?(1, 4) && parts.all? { |part| part.match?(INET_ATON_PART) }

    numbers = parts.map { |part| Integer(part) }
    head = numbers[0...-1]
    return unless head.all? { |n| n < 256 } && numbers.last < 256**(5 - parts.size)

    value = head.each_with_index.sum { |n, i| n << (8 * (3 - i)) } + numbers.last
    IPAddr.new(value, Socket::AF_INET)
  end
end
