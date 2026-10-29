# frozen_string_literal: true

module PlaceCal
  # Uploaded SVGs are served from the app's own origin, so opening one directly must not run any script in it.
  # Matched on content type rather than path, since the static file server also serves percent-encoded paths.
  class SvgSandboxHeaders
    HEADERS = {
      'content-security-policy' => "default-src 'none'; style-src 'unsafe-inline'; img-src data:; sandbox",
      'x-content-type-options' => 'nosniff'
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      content_type = headers['content-type'] || headers['Content-Type']
      headers.merge!(HEADERS) if content_type.to_s.start_with?('image/svg+xml')
      [status, headers, body]
    end
  end
end
