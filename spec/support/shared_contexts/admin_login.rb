# frozen_string_literal: true

RSpec.shared_context 'admin login' do
  let(:admin_user) { create(:root_user, email: 'admin@normalcal.org', password: 'password') }

  before do
    create_default_site
    login_as_admin
  end

  def login_as_admin
    visit '/users/sign_in'
    fill_in 'Email', with: admin_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end
end

RSpec.configure do |config|
  config.include_context 'admin login', :admin_login
end
