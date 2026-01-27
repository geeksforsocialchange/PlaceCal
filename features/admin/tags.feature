@admin @javascript
Feature: Tag Management
  As a root administrator
  I want to manage tags for categorising partners and events
  So that users can filter and find relevant content

  Background:
    Given I am logged in as a root user

  Scenario: Viewing the tags list
    When I go to the "Tags" admin section
    Then I should see "Tags"
    And I should see "Add Tag"

  Scenario: Creating a new category tag
    When I go to the "Tags" admin section
    And I click "Add Tag"
    Then I should see "New Tag"
    And I should see "Name"
    And I should see "Type"

  Scenario: Viewing an existing tag
    Given there is a tag called "Community Services"
    When I go to the "Tags" admin section
    And I click "Community Services"
    Then I should see "Community Services"

  Scenario: Different tag types are available
    When I go to the "Tags" admin section
    And I click "Add Tag"
    Then I should see "Category"

  Scenario: Tags can be assigned to partners
    Given there is a tag called "Youth Services"
    And there is a partner called "Greenfield Youth Centre"
    When I edit the partner "Greenfield Youth Centre"
    Then I should see "Tags"
