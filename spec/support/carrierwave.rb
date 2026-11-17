# frozen_string_literal: true

# The SSRF check resolves each image host over DNS before WebMock sees the request
CarrierWave.configure { |config| config.skip_ssrf_protection = true }
# Test event ids overlap the dev server's, so test images stay out of public/uploads
EventImageUploader.root = Rails.root.join("tmp/test_uploads")
