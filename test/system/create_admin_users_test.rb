require "application_system_test_case"

class CreateAdminUsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    given_a_root_user_exists

    visit '/'

    # assert_selector "h1", text: "CreateAdminUser"
  end

  def given_a_root_user_exists
    create :root
  end
end
