@public @wip
Feature: Browse Events
  As a community member
  I want to browse upcoming events
  So that I can find activities to participate in

  Background:
    Given there is a partner called "Riverside Community Hub"

  Scenario: Viewing the events page
    Given there is an event called "Coffee Morning"
    When I view the events page
    Then I should see "Events"

  Scenario: Viewing event details
    Given there is an event called "Community Lunch"
    When I view the events page
    Then I should see "Community Lunch"

  Scenario: Events are shown in chronological order
    Given the following events exist:
      | name              | date       |
      | Morning Yoga      | 2022-11-10 |
      | Afternoon Tea     | 2022-11-11 |
      | Evening Concert   | 2022-11-12 |
    When I view the events page
    Then I should see "Morning Yoga"
    And I should see "Afternoon Tea"
    And I should see "Evening Concert"

  Scenario: Paginator shows Next 7 days by default for week view
    Given there are 25 events in the next month
    When I view the events page
    Then I should see "Next 7 days" in the paginator

  Scenario: Today button appears when navigating away from today
    Given there are 25 events in the next month
    When I view the events page
    And I click the forward arrow
    Then I should see a "Today" button

  Scenario: Today button returns to current date
    Given there are 25 events in the next month
    When I view the events page
    And I click the forward arrow
    And I click "Today"
    Then I should see "Next 7 days" as active in the paginator

  Scenario: Go to date picker navigates to selected date
    Given there are 25 events in the next month
    When I view the events page
    And I click "Go to date"
    And I select the date "2022-11-20"
    Then I should not see "Next 7 days" as active in the paginator
