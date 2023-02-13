# frozen_string_literal: true

require 'test_helper'

class Admin::TagsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  setup do
    @root = create(:root)
    @citizen = create(:citizen)

    @tag = create(:tag)
    @system_tag = create(:system_tag)

    create_default_site
    host! 'admin.lvh.me'
  end

  test 'root user editing a tag can see system_tag option' do
    log_in_with @root.email
    visit edit_admin_tag_url(@tag)

    assert_selector 'input#tag_system_tag'
  end

  test 'citizen user editing a tag cannot see system_tag option' do
    log_in_with @citizen.email
    visit edit_admin_tag_url(@tag)

    assert_selector 'input#tag_system_tag', count: 0
  end

  test 'root users can modify system tag' do
    log_in_with @root.email

    visit edit_admin_tag_url(@tag)
    fill_in 'Name', with: 'A new tag name'
    click_button 'Save'

    assert_has_flash :success, 'Tag was saved successfully'

    # this should be the tags index page
    assert_content 'A new tag name'
  end

  test 'citizen users cannot modify tag' do
    @citizen.tags << @tag
    @citizen.tags << @system_tag

    log_in_with @citizen.email

    visit edit_admin_tag_url(@system_tag)

    assert_content 'This tag is a system tag meaning that it cannot be edited by non-root admins.'
  end

  test 'root users can make a tag a system tag' do
    log_in_with @root.email

    # toggle on
    visit edit_admin_tag_url(@tag)
    check 'System tag'
    click_button 'Save'
    assert_has_flash :success, 'Tag was saved successfully'

    # check is toggled
    visit edit_admin_tag_url(@tag)
    assert_selector :xpath, '//input[@name="tag[system_tag]"][@checked="checked"]'

    # now toggle off
    uncheck 'System tag'
    click_button 'Save'
    assert_has_flash :success, 'Tag was saved successfully'

    # check is NOT toggled
    visit edit_admin_tag_url(@tag)
    assert_selector :xpath, '//input[@name="tag[system_tag]"][@checked="checked"]', count: 0
  end

  private

  def assert_has_flash(type, message)
    assert_css ".flashes .alert-#{type}", text: message
  end

  def log_in_with(email, password = 'password')
    # NOTE: make sure you have a default site set up in DB
    visit 'http://lvh.me/users/sign_in'
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    click_button 'Log in'
  end
end
