@admin @javascript
Feature: Admin Dashboard
  As an administrator
  I want to see an overview dashboard
  So that I can quickly understand the state of the system

  Background:
    Given I am logged in as a root user

  Scenario: Dashboard shows quick add buttons
    When I visit the admin dashboard
    Then I should see "New Partner"
    And I should see "New Calendar"
    And I should see "New User"

  Scenario: Dashboard shows recently updated partners
    Given there is a partner called "Active Community Centre"
    When I visit the admin dashboard
    Then I should see "Updated Partners"
    And I should see "Active Community Centre"
