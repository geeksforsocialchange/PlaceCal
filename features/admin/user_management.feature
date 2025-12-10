@admin
Feature: User Management
  As a root administrator
  I want to manage user accounts
  So that the right people have access to administer partners and sites

  Background:
    Given I am logged in as a root user

  Scenario: Root user can access user management
    When I go to the "Users" admin section
    Then I should see "Users"
    And I should see "Add New User"

  Scenario: Logging out
    When I log out
    Then I should be logged out
