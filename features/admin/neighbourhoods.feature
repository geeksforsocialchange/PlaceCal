@admin @javascript
Feature: Neighbourhood Management
  As a root administrator
  I want to manage neighbourhoods
  So that partners and events can be associated with geographic areas

  Background:
    Given I am logged in as a root user

  Scenario: Viewing the neighbourhoods list
    When I go to the "Neighbourhoods" admin section
    Then I should see "Neighbourhoods"
    And I should see "Neighbourhood Roots"

  Scenario: Viewing an existing neighbourhood
    Given there is a neighbourhood called "Riverside"
    When I go to the "Neighbourhoods" admin section
    And I click "Riverside"
    Then I should see "Riverside"

  Scenario: Neighbourhood edit form shows fields
    Given there is a neighbourhood called "Riverside"
    When I go to the "Neighbourhoods" admin section
    And I click "Riverside"
    And I click "Edit"
    Then I should see "Name"
