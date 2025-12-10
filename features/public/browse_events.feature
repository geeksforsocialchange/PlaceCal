@public
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
