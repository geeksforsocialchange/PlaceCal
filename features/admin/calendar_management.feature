@admin @javascript
Feature: Calendar Administration
  As a root administrator
  I want to manage all calendars in the system
  So that I can oversee event imports from external sources

  Background:
    Given I am logged in as a root user
    And there is a partner called "Riverside Community Hub"

  # Calendar Index and Navigation
  Scenario: Viewing calendar list
    Given there is a calendar called "Weekly Activities" for partner "Riverside Community Hub"
    And there is a calendar called "Special Events" for partner "Riverside Community Hub"
    When I go to the "Calendars" admin section
    Then I should see "Weekly Activities"
    And I should see "Special Events"

  Scenario: Viewing a calendar
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I view the calendar "Community Events"
    Then I should see "Community Events"
    And I should see "Riverside Community Hub"

  # Calendar Creation
  Scenario: Add new calendar button is visible
    When I go to the "Calendars" admin section
    Then I should see "Add Calendar"

  Scenario: New calendar form shows required fields
    When I go to the "Calendars" admin section
    And I click "Add Calendar"
    Then I should see "Partner Organiser"
    And I should see "Name"
    And I should see "URL"

  # Calendar Deletion
  Scenario: Deleting a calendar
    Given there is a calendar called "Temporary Calendar" for partner "Riverside Community Hub"
    When I edit the calendar "Temporary Calendar"
    And I click the "Admin" tab
    And I click "Delete Calendar"
    Then I should see a success message
