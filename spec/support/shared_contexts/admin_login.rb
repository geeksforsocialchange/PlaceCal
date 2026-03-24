# frozen_string_literal: true

RSpec.shared_context "admin login" do
  let(:admin_user) { create(:root_user, email: "admin@placecal.org", password: "password", password_confirmation: "password") }

  before do
    create_default_site
    sign_in_as_admin
  end

  def sign_in_as_admin
    sign_in_as(admin_user)
  end
end

RSpec.configure do |config|
  config.include_context "admin login", :admin_login
end
