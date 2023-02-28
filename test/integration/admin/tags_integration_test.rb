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

  test 'creating and editing FacilityTag' do
    log_in_with @root.email

    click_link 'Tags'
    click_link 'Add New Tag'

    # create

    # should see type selector box
    assert_selector :xpath, '//select[@name="tag[type]"]'

    fill_in 'Name', with: 'AlphaFacility'
    fill_in 'Slug', with: 'alpha-facility'
    fill_in 'Description', with: 'The description of this tag.'
    select 'Facility', from: 'Type'

    click_button 'Save'
    assert_has_flash :success, 'Tag has been created'

    click_link Tag.last.name

    # should not be able to choose type on update
    assert_selector :xpath, '//select[@name="tag[type]"]', count: 0

    assert_selector :xpath, '//input[@name="tag[name]"][@value="AlphaFacility"]'
    assert_selector :xpath, '//input[@name="tag[slug]"][@value="alpha-facility"]'

    # change values
    fill_in 'Name', with: 'AlphaFacility 2'
    fill_in 'Slug', with: 'alpha-facility-2'
    fill_in 'Description', with: 'The description has changed.'
    click_button 'Save'

    assert_has_flash :success, 'Tag was saved successfully'

    # Tag should save okay
    click_link Tag.last.name

    assert_selector :xpath, '//input[@name="tag[name]"][@value="AlphaFacility 2"]'
    assert_selector :xpath, '//input[@name="tag[slug]"][@value="alpha-facility-2"]'
  end

  # Assigned user field
  test 'shows assigned user field on New' do
    log_in_with @root.email
    visit new_admin_tag_url

    assert_css 'h2', text: 'Assigned Users'
  end

  test 'shows assigned user field on Edit of Partnership tag' do
    log_in_with @root.email

    partnership_tag = create(:tag, type: 'Partnership')
    visit edit_admin_tag_url(partnership_tag)

    assert_css 'h2', text: 'Assigned Users'
  end

  test 'hides assigned user field on Edit of tag that is not a Partnership' do
    log_in_with @root.email

    facility_tag = create(:tag, type: 'Facility')
    visit edit_admin_tag_url(facility_tag)

    assert_css 'h2', text: 'Assigned Users', count: 0
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
