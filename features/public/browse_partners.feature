@public @wip
Feature: Browse Partners
  As a community member
  I want to browse local organisations
  So that I can find services and support in my area

  Scenario: Viewing the partners page
    Given there is a partner called "Riverside Community Hub"
    When I visit the partners page
    Then I should see "Riverside Community Hub"

  Scenario: Partner details show contact information
    Given there is a partner called "Oldtown Library"
    When I visit the partners page
    Then I should see "Oldtown Library"

  Scenario: Partner page shows paginator when many events
    Given there is a partner called "Riverside Community Hub"
    And the partner has 35 upcoming events
    When I visit the partner page for "Riverside Community Hub"
    Then I should see a paginator

  Scenario: Partner paginator navigates within partner page
    Given there is a partner called "Riverside Community Hub"
    And the partner has 35 upcoming events
    When I visit the partner page for "Riverside Community Hub"
    And I click the forward arrow
    Then I should still be on the partner page for "Riverside Community Hub"
    And I should see a "Today" button

  Scenario: Partner page Today button returns to current date
    Given there is a partner called "Riverside Community Hub"
    And the partner has 35 upcoming events
    When I visit the partner page for "Riverside Community Hub"
    And I click the forward arrow
    And I click "Today"
    Then I should see "Next 7 days" as active in the paginator
