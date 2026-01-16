# frozen_string_literal: true

@admin @javascript
Feature: Partner Index Table
  As an administrator
  I want to view and filter partners in a table
  So that I can quickly find and manage community organisations

  Background:
    Given I am logged in as a root user
    And there is a neighbourhood called "Central Ward"
    And there is a neighbourhood called "Riverside Ward"
    And there is a partnership tag called "Age Friendly"
    And there is a partnership tag called "Community First"
    And there is a category tag called "Health"

  # Table Display
  Scenario: Partner index table shows correct columns
    Given there is a partner called "Community Hub"
    When I go to the "Partners" admin section
    Then I should see the partner table with columns:
      | Partner | Neighbourhood | Partnerships | Last Updated |

  Scenario: Partner table shows partner with ward from address
    Given there is a partner called "Central Library" in "Central Ward"
    When I go to the "Partners" admin section
    Then I should see "Central Library" in the partner table
    And I should see "Central Ward" in the partner table

  Scenario: Partner table shows partnerships for a partner
    Given there is a partner called "Age Friendly Org"
    And the partner "Age Friendly Org" has the partnership "Age Friendly"
    When I go to the "Partners" admin section
    Then I should see "Age Friendly Org" in the partner table
    And I should see "Age Friendly" in the partner table

  Scenario: Partner table shows calendar status
    Given there is a partner called "Partner With Calendar"
    And the partner "Partner With Calendar" has a calendar
    When I go to the "Partners" admin section
    Then I should see a calendar connected indicator for "Partner With Calendar"

  Scenario: Partner table shows admin status
    Given there is a partner called "Partner With Admin"
    And the partner "Partner With Admin" has an admin user
    When I go to the "Partners" admin section
    Then I should see an admin indicator for "Partner With Admin"

  # Filtering by Dropdown
  Scenario: Filter partners by calendar status - connected
    Given there is a partner called "Has Calendar" with a calendar
    And there is a partner called "No Calendar"
    When I go to the "Partners" admin section
    And I filter by "Calendar" with value "Connected"
    Then I should see "Has Calendar" in the partner table
    And I should not see "No Calendar" in the partner table

  Scenario: Filter partners by calendar status - none
    Given there is a partner called "Has Calendar" with a calendar
    And there is a partner called "No Calendar"
    When I go to the "Partners" admin section
    And I filter by "Calendar" with value "No calendar"
    Then I should see "No Calendar" in the partner table
    And I should not see "Has Calendar" in the partner table

  Scenario: Filter partners by admin status - has admins
    Given there is a partner called "With Admin"
    And the partner "With Admin" has an admin user
    And there is a partner called "Without Admin"
    When I go to the "Partners" admin section
    And I filter by "Admins" with value "Has admins"
    Then I should see "With Admin" in the partner table
    And I should not see "Without Admin" in the partner table

  Scenario: Filter partners by admin status - no admins
    Given there is a partner called "With Admin"
    And the partner "With Admin" has an admin user
    And there is a partner called "Without Admin"
    When I go to the "Partners" admin section
    And I filter by "Admins" with value "No admins"
    Then I should see "Without Admin" in the partner table
    And I should not see "With Admin" in the partner table

  Scenario: Filter partners by partnership
    Given there is a partner called "Age Friendly Partner"
    And the partner "Age Friendly Partner" has the partnership "Age Friendly"
    And there is a partner called "Community Partner"
    And the partner "Community Partner" has the partnership "Community First"
    When I go to the "Partners" admin section
    And I filter by "Partnership" with value "Age Friendly"
    Then I should see "Age Friendly Partner" in the partner table
    And I should not see "Community Partner" in the partner table

  # Clicking to Filter
  Scenario: Click on partnership name to filter by that partnership
    Given there is a partner called "Age Friendly Partner"
    And the partner "Age Friendly Partner" has the partnership "Age Friendly"
    And there is a partner called "Community Partner"
    And the partner "Community Partner" has the partnership "Community First"
    When I go to the "Partners" admin section
    And I click the partnership "Age Friendly" in the partner table
    Then I should see "Age Friendly Partner" in the partner table
    And I should not see "Community Partner" in the partner table
    And the "Partnership" filter should show "Age Friendly"

  # Clear Filters
  Scenario: Clear filters button appears when filters are active
    Given there is a partner called "Test Partner"
    When I go to the "Partners" admin section
    Then I should not see "Clear filters"
    When I filter by "Calendar" with value "Connected"
    Then I should see "Clear filters"

  Scenario: Clear filters resets all active filters
    Given there is a partner called "Has Calendar" with a calendar
    And there is a partner called "No Calendar"
    When I go to the "Partners" admin section
    And I filter by "Calendar" with value "Connected"
    Then I should not see "No Calendar" in the partner table
    When I click "Clear filters"
    Then I should see "Has Calendar" in the partner table
    And I should see "No Calendar" in the partner table

  # Search
  Scenario: Search filters partners by name
    Given there is a partner called "Community Library"
    And there is a partner called "Youth Centre"
    When I go to the "Partners" admin section
    And I search for "Library" in the partner table
    Then I should see "Community Library" in the partner table
    And I should not see "Youth Centre" in the partner table
