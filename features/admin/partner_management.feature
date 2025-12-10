@admin
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
