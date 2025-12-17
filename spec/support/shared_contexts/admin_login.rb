# frozen_string_literal: true

RSpec.shared_context 'admin login' do
  let(:admin_user) { create(:root_user, email: 'admin@placecal.org', password: 'password', password_confirmation: 'password') }

  before do
    create_default_site
    login_as_admin
  end

  def login_as_admin
    # Visit admin subdomain for login
    port = Capybara.current_session.server.port
    visit "http://admin.lvh.me:#{port}/users/sign_in"
    fill_in 'Email', with: admin_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end
end

RSpec.configure do |config|
  config.include_context 'admin login', :admin_login
end
