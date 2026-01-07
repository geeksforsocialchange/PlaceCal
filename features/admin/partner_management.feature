@admin @javascript
Feature: Partner Administration
  As a root administrator
  I want to manage all partners in the system
  So that I can oversee community organisations

  Background:
    Given I am logged in as a root user

  # Partner Index and Navigation
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

  # Partner Creation
  Scenario: Creating a new partner
    When I create a new partner with name "Riverside Community Hub"
    Then I should see a success message
    And I should see the partner "Riverside Community Hub" in the list

  # Partner Deletion (Root Only)
  Scenario: Deleting a partner
    Given there is a partner called "Temporary Partner"
    When I edit the partner "Temporary Partner"
    And I click "Delete Partner"
    Then I should see a success message
    And I should not see "Temporary Partner"

  # Moderation (Root Only)
  Scenario: Root user can see moderation section
    Given there is a partner called "Moderation Test Partner"
    When I edit the partner "Moderation Test Partner"
    Then I should see "Moderation"
    And I should see "Hidden"

  Scenario: Hiding a partner with reason
    Given there is a partner called "Problem Partner"
    When I edit the partner "Problem Partner"
    And I check "Hidden"
    And I fill in "Explanation for hiding" with "Spam content detected"
    And I click the "Save Partner" button
    Then I should see a success message
