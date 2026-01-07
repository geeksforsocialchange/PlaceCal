@admin @javascript
Feature: Supporter Management
  As a root administrator
  I want to manage supporters
  So that funding partners can be displayed on PlaceCal

  Background:
    Given I am logged in as a root user

  Scenario: Viewing the supporters list
    When I go to the "Supporters" admin section
    Then I should see "Supporters"
    And I should see "Add New Supporter"

  Scenario: Creating a new supporter form
    When I go to the "Supporters" admin section
    And I click "Add New Supporter"
    Then I should see "Create a new Supporter"
    And I should see "Name"
    And I should see "Url"

  Scenario: Viewing an existing supporter
    Given there is a supporter called "Local Council"
    When I go to the "Supporters" admin section
    Then I should see "Local Council"
