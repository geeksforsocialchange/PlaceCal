# frozen_string_literal: true

# Shared context for admin request specs
# Provides admin_host and common user factory helpers
RSpec.shared_context 'admin request' do
  let(:admin_host) { 'admin.lvh.me' }
end

RSpec.configure do |config|
  config.include_context 'admin request', type: :request, file_path: %r{spec/requests/admin/}
end
