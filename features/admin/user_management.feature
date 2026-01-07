@admin @javascript
Feature: User Administration
  As a root administrator
  I want to manage user accounts
  So that the right people have access to administer partners and sites

  Background:
    Given I am logged in as a root user

  # User Index and Navigation
  Scenario: Viewing user list
    When I go to the "Users" admin section
    Then I should see "Users"
    And I should see "Add New User"

  Scenario: User list shows existing users
    Given there is a user called "Alice Smith"
    And there is a user called "Bob Jones"
    When I go to the "Users" admin section
    Then I should see "Alice"
    And I should see "Bob"

  # User Creation
  Scenario: New user form shows required fields
    When I go to the "Users" admin section
    And I click "Add New User"
    Then I should see "First name"
    And I should see "Last name"
    And I should see "Email"

  # Authentication
  Scenario: Logging out
    When I log out
    Then I should be logged out
