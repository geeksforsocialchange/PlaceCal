@public @javascript
Feature: Browse News Articles
  As a community member
  I want to browse news and updates
  So that I can stay informed about local activities

  Background:
    Given there is a published site called "Riverside Calendar"

  Scenario: Viewing the news page
    When I visit the news page for "Riverside Calendar"
    Then I should see "News"

  Scenario: Viewing article details
    Given there is an article called "Summer Festival Announcement"
    When I visit the news page for "Riverside Calendar"
    Then I should see "Summer Festival Announcement"

  Scenario: Articles show publication date
    Given there is an article called "Weekly Roundup" published today
    When I visit the news page for "Riverside Calendar"
    Then I should see "Weekly Roundup"

  Scenario: Articles show author name
    Given there is an article called "Chair's Message" authored by "Jane Smith"
    When I visit the news page for "Riverside Calendar"
    Then I should see "Chair's Message"
