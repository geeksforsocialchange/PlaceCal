@admin @javascript
Feature: Site Management
  As a root administrator
  I want to manage PlaceCal sites
  So that communities can have their own branded calendar pages

  Background:
    Given I am logged in as a root user

  Scenario: Viewing the sites list
    When I go to the "Sites" admin section
    Then I should see "Sites"
    And I should see "Add Site"

  Scenario: Creating a new site
    When I go to the "Sites" admin section
    And I click "Add Site"
    Then I should see "New Site"
    And I should see "Name"
    And I should see "Site Admin"

  Scenario: Viewing an existing site
    Given there is a site called "Riverside Calendar"
    When I go to the "Sites" admin section
    And I click "Riverside Calendar"
    Then I should see "Riverside Calendar"

  Scenario: Sites have neighbourhood configuration
    Given there is a site called "Community Calendar"
    When I go to the "Sites" admin section
    And I click "Community Calendar"
    Then I should see "Neighbourhoods"
