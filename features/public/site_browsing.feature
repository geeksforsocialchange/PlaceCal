@public @javascript
Feature: Browse Site Content
  As a community member
  I want to browse content on my local PlaceCal site
  So that I can find relevant events and organisations in my area

  Background:
    Given there is a published site called "Riverside Calendar"

  Scenario: Viewing the site homepage
    When I visit the site "Riverside Calendar"
    Then I should see "Riverside Calendar"

  Scenario: Site shows local events
    Given there is a partner called "Riverside Community Hub" in the site "Riverside Calendar"
    And there is an event called "Coffee Morning" for partner "Riverside Community Hub"
    When I visit the events page for site "Riverside Calendar"
    Then I should see "Coffee Morning"

  Scenario: Site shows local partners
    Given there is a partner called "Riverside Community Hub" in the site "Riverside Calendar"
    When I visit the partners page for site "Riverside Calendar"
    Then I should see "Riverside Community Hub"

  Scenario: Events can be filtered by date
    Given there is a partner called "Riverside Community Hub" in the site "Riverside Calendar"
    And there is an event called "Weekly Yoga" on "2022-11-15"
    When I visit the events page for site "Riverside Calendar"
    Then I should see "Weekly Yoga"

  Scenario: Partners show their upcoming events
    Given there is a partner called "Riverside Community Hub" in the site "Riverside Calendar"
    And there is an event called "Open Day" for partner "Riverside Community Hub"
    When I visit the partner "Riverside Community Hub" on site "Riverside Calendar"
    Then I should see "Riverside Community Hub"
