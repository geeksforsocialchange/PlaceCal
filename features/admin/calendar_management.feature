@admin
Feature: Calendar Management
  As an administrator
  I want to manage calendars that import events
  So that events are automatically synced from external sources

  Background:
    Given I am logged in as a root user
    And there is a partner called "Riverside Community Hub"

  Scenario: Viewing a calendar
    Given there is a calendar called "Community Events" for partner "Riverside Community Hub"
    When I view the calendar "Community Events"
    Then I should see "Community Events"
    And I should see "Riverside Community Hub"

  Scenario: Calendar list shows all calendars
    Given there is a calendar called "Weekly Activities" for partner "Riverside Community Hub"
    And there is a calendar called "Special Events" for partner "Riverside Community Hub"
    When I go to the "Calendars" admin section
    Then I should see "Weekly Activities"
    And I should see "Special Events"
