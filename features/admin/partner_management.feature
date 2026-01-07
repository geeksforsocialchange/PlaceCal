@admin @javascript
Feature: Partner Management
  As an administrator
  I want to manage partners in the system
  So that community organisations can share their events

  Background:
    Given I am logged in as a root user

  Scenario: Creating a new partner
    When I create a new partner with name "Riverside Community Hub"
    Then I should see a success message
    And I should see the partner "Riverside Community Hub" in the list

  Scenario: Editing an existing partner
    Given there is a partner called "Oldtown Library"
    When I edit the partner "Oldtown Library"
    And I update the partner summary to "A welcoming community library"
    Then I should see a success message
    And the partner "Oldtown Library" should have summary "A welcoming community library"

  Scenario: Viewing partner list
    Given the following partners exist:
      | name                    | summary                        |
      | Riverside Community Hub | Community services for all     |
      | Oldtown Library         | Books and community activities |
      | Greenfield Youth Centre | Youth services and activities  |
    When I go to the "Partners" admin section
    Then I should see "Riverside Community Hub"
    And I should see "Oldtown Library"
    And I should see "Greenfield Youth Centre"

  Scenario: Partner edit form shows all sections
    Given there is a partner called "Community Centre"
    When I edit the partner "Community Centre"
    Then I should see "Basic Information"
    And I should see "Place"
    And I should see "Online"
    And I should see "Contact Information"

  Scenario: Updating partner description
    Given there is a partner called "Oldtown Library"
    When I edit the partner "Oldtown Library"
    And I fill in "Description" with "A historic library serving the community since 1920"
    And I click the "Save Partner" button
    Then I should see a success message

  Scenario: Partner form shows tag sections
    Given there is a partner called "Youth Centre"
    And there is a partnership tag called "Millbrook Partnership"
    When I edit the partner "Youth Centre"
    Then I should see "Partnerships"
    And I should see "Categories"
    And I should see "Facilities"

  Scenario: Deleting a partner
    Given there is a partner called "Temporary Partner"
    When I edit the partner "Temporary Partner"
    And I click "Delete Partner"
    Then I should see a success message
    And I should not see "Temporary Partner"
