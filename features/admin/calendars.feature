@admin @javascript
Feature: Calendar Editing
  As a calendar editor
  I want to edit calendar details
  So that events are imported correctly from external sources

  Background:
    Given I am logged in as a root user
    And there is a partner called "Riverside Community Hub"

  # Form Section Visibility
  Scenario: Calendar edit form shows all sections
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I edit the calendar "Community Events"
    Then I should see "Details"
    And I should see "Location"
    And I should see "Public Contact Information"

  Scenario: Calendar form shows details fields
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I edit the calendar "Community Events"
    Then I should see "Partner Organiser"
    And I should see "Name"
    And I should see "URL"
    And I should see "Importer mode"

  Scenario: Calendar form shows location fields
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I edit the calendar "Community Events"
    Then I should see "Default location"
    And I should see "Where should location information for this calendar come from?"

  # Basic Fields
  Scenario: Updating calendar name
    Given there is a calendar called "Old Calendar Name" for partner "Riverside Community Hub"
    When I edit the calendar "Old Calendar Name"
    And I fill in "Name" with "New Calendar Name"
    And I click the "Update Calendar" button
    Then I should see a success message

  Scenario: Calendar form shows URL field
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I edit the calendar "Community Events"
    Then I should see "URL"
    And I should see "Calendar source URLs that PlaceCal currently supports"

  # Partner Selection (Drop Down Select Box)
  Scenario: Calendar shows partner selection
    Given there is a partner called "Another Partner"
    Given there is a calendar called "Shared Events" for partner "Riverside Community Hub"
    When I edit the calendar "Shared Events"
    Then I should see "Partner Organiser"
    And I should see "Which group organises these events?"

  # Location Strategy
  Scenario: Selecting calendar location strategy
    Given there is a calendar called "Location Test" for partner "Riverside Community Hub"
    When I edit the calendar "Location Test"
    Then I should see "Where should location information for this calendar come from?"

  # Public Contact Information
  Scenario: Updating calendar public contact name
    Given there is a calendar called "Contact Test Calendar" for partner "Riverside Community Hub"
    When I edit the calendar "Contact Test Calendar"
    And I fill in "Public contact name" with "Event Coordinator"
    And I click the "Update Calendar" button
    Then I should see a success message

  Scenario: Updating calendar public contact email
    Given there is a calendar called "Email Test Calendar" for partner "Riverside Community Hub"
    When I edit the calendar "Email Test Calendar"
    And I fill in "Public contact email" with "events@example.org"
    And I click the "Update Calendar" button
    Then I should see a success message

  Scenario: Updating calendar public contact phone
    Given there is a calendar called "Phone Test Calendar" for partner "Riverside Community Hub"
    When I edit the calendar "Phone Test Calendar"
    And I fill in "Public contact phone" with "0161 555 1234"
    And I click the "Update Calendar" button
    Then I should see a success message

  Scenario: Updating all calendar contact fields
    Given there is a calendar called "Full Contact Calendar" for partner "Riverside Community Hub"
    When I edit the calendar "Full Contact Calendar"
    And I fill in "Public contact name" with "Calendar Manager"
    And I fill in "Public contact email" with "calendar@example.org"
    And I fill in "Public contact phone" with "0161 555 9999"
    And I click the "Update Calendar" button
    Then I should see a success message
