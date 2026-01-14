@admin @javascript
Feature: Partner Editing
  As a partner editor
  I want to edit partner details
  So that community organisations have accurate information

  Background:
    Given I am logged in as a root user

  # Form Section Visibility (tabbed form)
  Scenario: Partner edit form shows all sections across tabs
    Given there is a partner called "Community Centre"
    When I edit the partner "Community Centre"
    Then I should see "Basic Information"
    When I go to the "Location" step
    Then I should see "Location"
    And I should see "Opening Times"
    When I go to the "Contact" step
    Then I should see "Online Presence"
    And I should see "Public Contact"
    When I go to the "Tags" step
    Then I should see "Tags & Associations"
    When I go to the "Settings" step
    Then I should see "Event Matching"

  Scenario: Partner form shows tag sections
    Given there is a partner called "Youth Centre"
    And there is a partnership tag called "Millbrook Partnership"
    When I edit the partner "Youth Centre"
    And I go to the "Tags" step
    Then I should see "Partnerships"
    And I should see "Categories"
    And I should see "Facilities"

  # Basic Information Fields
  Scenario: Updating partner name
    Given there is a partner called "Old Name Centre"
    When I edit the partner "Old Name Centre"
    And I fill in "Name" with "New Name Centre"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating partner summary
    Given there is a partner called "Oldtown Library"
    When I edit the partner "Oldtown Library"
    And I update the partner summary to "A welcoming community library"
    Then I should see a success message
    And the partner "Oldtown Library" should have summary "A welcoming community library"

  Scenario: Updating partner description
    Given there is a partner called "Oldtown Library"
    When I edit the partner "Oldtown Library"
    And I fill in "Description" with "A historic library serving the community since 1920"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating partner accessibility information
    Given there is a partner called "Accessible Venue"
    When I edit the partner "Accessible Venue"
    And I fill in "Accessibility Information" with "Step-free access via rear entrance"
    And I click the "Save" button
    Then I should see a success message

  # Address Fields (Place step)
  Scenario: Updating partner street address
    Given there is a partner called "Downtown Office"
    When I edit the partner "Downtown Office"
    And I go to the "Place" step
    And I fill in "Street address" with "456 High Street"
    And I fill in "City" with "Millbrook"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Partner address form shows all fields
    Given there is a partner called "Address Test Partner"
    When I edit the partner "Address Test Partner"
    And I go to the "Place" step
    Then I should see "Street address"
    And I should see "City"
    And I should see "Postcode"

  # Online Fields (Contact step)
  Scenario: Updating partner website
    Given there is a partner called "Web Presence Org"
    When I edit the partner "Web Presence Org"
    And I go to the "Contact" step
    And I fill in "Website" with "https://example.org"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating partner social media handles
    Given there is a partner called "Social Media Org"
    When I edit the partner "Social Media Org"
    And I go to the "Contact" step
    And I fill in "partner_facebook_link" with "SocialMediaOrgPage"
    And I fill in "partner_twitter_handle" with "SocialMediaOrg"
    And I fill in "partner_instagram_handle" with "socialmediaorg"
    And I click the "Save" button
    Then I should see a success message

  # Contact Information Fields (Contact step)
  Scenario: Updating public contact information
    Given there is a partner called "Contact Info Test"
    When I edit the partner "Contact Info Test"
    And I go to the "Contact" step
    And I fill in "partner_public_name" with "John Smith"
    And I fill in "partner_public_email" with "public@example.org"
    And I fill in "partner_public_phone" with "0161 123 4567"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating partnership contact information
    Given there is a partner called "Partnership Contact Test"
    When I edit the partner "Partnership Contact Test"
    And I go to the "Contact" step
    And I fill in "partner_partner_name" with "Jane Doe"
    And I fill in "partner_partner_email" with "partner@example.org"
    And I fill in "partner_partner_phone" with "0161 987 6543"
    And I click the "Save" button
    Then I should see a success message

  # Tag Fields (Tags step) - categories and facilities are now checkboxes
  Scenario: Adding categories to a partner
    Given there is a partner called "Categorised Partner"
    And there is a category tag called "Health & Wellbeing"
    And there is a category tag called "Arts & Culture"
    When I edit the partner "Categorised Partner"
    And I go to the "Tags" step
    And I check "Health & Wellbeing"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Adding facilities to a partner
    Given there is a partner called "Accessible Partner"
    And there is a facility tag called "Wheelchair Accessible"
    And there is a facility tag called "Parking Available"
    When I edit the partner "Accessible Partner"
    And I go to the "Tags" step
    And I check "Wheelchair Accessible"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Adding partnerships to a partner
    Given there is a partner called "Partnered Org"
    And there is a partnership tag called "Millbrook Together"
    When I edit the partner "Partnered Org"
    And I go to the "Tags" step
    And I select "Millbrook Together" from the "Partnerships" drop down select box
    And I click the "Save" button
    Then I should see a success message

  # Service Areas (Place step)
  # TODO: Service areas now use cascading neighbourhood dropdowns requiring AJAX setup
  @wip
  Scenario: Adding a service area to a partner
    Given there is a partner called "Outreach Service"
    And there is a neighbourhood called "Central Ward"
    When I edit the partner "Outreach Service"
    And I go to the "Place" step
    And I click "Add Service Area"
    And I select "Central Ward" from the service area drop down select box
    And I click the "Save" button
    Then I should see a success message

  # Opening Times (Place step)
  Scenario: Partner form shows opening times controls
    Given there is a partner called "Business Hours Partner"
    When I edit the partner "Business Hours Partner"
    And I go to the "Place" step
    Then I should see "Opening Times"
    And I should see "Day"
    And I should see "Opens"
    And I should see "Closes"

  Scenario: Adding opening times to a partner
    Given there is a partner called "9 to 5 Partner"
    When I edit the partner "9 to 5 Partner"
    And I go to the "Place" step
    And I add opening time "Monday" from "09:00" to "17:00"
    And I click the "Save" button
    Then I should see a success message

  # Event Matching (Settings step)
  Scenario: Enabling event matching for a partner
    Given there is a partner called "Event Venue"
    When I edit the partner "Event Venue"
    And I go to the "Settings" step
    And I check "partner_can_be_assigned_events"
    And I click the "Save" button
    Then I should see a success message
