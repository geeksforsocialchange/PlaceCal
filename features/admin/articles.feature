@admin @javascript
Feature: Article Management
  As an administrator
  I want to manage news articles
  So that communities can share news and updates

  Background:
    Given I am logged in as a root user
    And there is a partner called "Riverside Community Hub"

  Scenario: Viewing the articles list
    When I go to the "Articles" admin section
    Then I should see "Articles"
    And I should see "Add Article"

  Scenario: Creating a new article
    When I go to the "Articles" admin section
    And I click "Add Article"
    Then I should see "New Article"
    And I should see "Title"
    And I should see "Body"

  Scenario: Viewing an existing article
    Given there is an article called "Community Update"
    When I go to the "Articles" admin section
    And I click "Community Update"
    Then I should see "Community Update"

  Scenario: Articles can be associated with partners
    When I go to the "Articles" admin section
    And I click "Add Article"
    Then I should see "Partner"

  Scenario: Articles list shows author information
    Given there is an article called "Weekly News" authored by "Admin User"
    When I go to the "Articles" admin section
    Then I should see "Weekly News"
