# frozen_string_literal: true

class Rack::Attack
  # Throttle API requests by IP: 100 requests per minute
  throttle('api/ip', limit: 100, period: 60) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Throttle GraphiQL requests by IP: 20 requests per minute
  throttle('graphiql/ip', limit: 20, period: 60) do |req|
    req.ip if req.path.start_with?('/graphiql')
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
