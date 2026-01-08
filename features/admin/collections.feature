@admin @javascript
Feature: Collection Management
  As a root administrator
  I want to manage event collections
  So that events can be grouped for special displays

  Background:
    Given I am logged in as a root user

  Scenario: Viewing the collections list
    When I go to the "Collections" admin section
    Then I should see "Collections"
    And I should see "Add Collection"

  Scenario: Creating a new collection form
    When I go to the "Collections" admin section
    And I click "Add Collection"
    Then I should see "Create a new Collection"
    And I should see "Name"

  Scenario: Viewing an existing collection
    Given there is a collection called "Summer Events"
    When I go to the "Collections" admin section
    Then I should see "Summer Events"
