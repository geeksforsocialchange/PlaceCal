@public
Feature: Browse Partners
  As a community member
  I want to browse local organisations
  So that I can find services and support in my area

  Scenario: Viewing the partners page
    Given there is a partner called "Riverside Community Hub"
    When I visit the home page
    And I click "Partners"
    Then I should see "Partners"

  Scenario: Partner details show contact information
    Given there is a partner called "Oldtown Library"
    When I visit the home page
    And I click "Partners"
    Then I should see "Oldtown Library"
