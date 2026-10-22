# frozen_string_literal: true

class Rack::Attack
  # Rails' remote_ip, which knows Cloudflare's proxies; Rack's req.ip would be the edge
  def self.client_ip(req)
    req.env['action_dispatch.remote_ip'].to_s.presence || req.ip
  end

  # Throttle API requests by IP: 100 requests per minute
  throttle('api/ip', limit: 100, period: 60) do |req|
    client_ip(req) if req.path.start_with?('/api/')
  end

  # Throttle GraphiQL requests by IP: 20 requests per minute
  throttle('graphiql/ip', limit: 20, period: 60) do |req|
    client_ip(req) if req.path.start_with?('/graphiql')
  end

  # Return JSON 429 for API requests
  self.throttled_responder = lambda do |request|
    if request.path.start_with?('/api/')
      [429, { 'Content-Type' => 'application/json' }, [{ errors: [{ message: 'Rate limit exceeded. Try again later.' }] }.to_json]]
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded. Try again later.']]
    end
  end
end
