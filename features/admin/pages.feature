@admin @javascript
Feature: Site Page Management
  As a site admin
  I want to write static pages for my site
  So that my community can read about us without a developer

  Background:
    Given I am a site admin for "Riverside Calendar"
    And I am logged in

  Scenario: Viewing the pages list
    When I go to the "Pages" admin section
    Then I should see "Pages"
    And I should see "Add Page"

  Scenario: Creating a page
    When I go to the "Pages" admin section
    And I click "Add Page"
    Then I should see "New Page"
    When I fill in "Title" with "About us"
    And I fill in "Slug" with "about"
    And I fill in "Body" with "We are a community calendar."
    And I click "Save"
    Then I should see a success message
    And the site "Riverside Calendar" should have a page at "about"

  Scenario: A reserved slug is rejected
    When I go to the "Pages" admin section
    And I click "Add Page"
    Then I should see "New Page"
    When I fill in "Title" with "Events"
    And I fill in "Slug" with "events"
    And I click "Save"
    Then I should see "reserved by PlaceCal"

  Scenario: Editing an existing page
    Given the site "Riverside Calendar" has a page called "Getting Involved"
    When I go to the "Pages" admin section
    And I click "Getting Involved"
    Then I should see "Getting Involved"
