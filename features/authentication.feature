@authentication @wip
Feature: User Authentication
  As a user
  I want to log in and out of the system
  So that I can access admin features securely

  Scenario: Successful login
    Given I am a root user
    When I visit the home page
    And I click "Sign in"
    And I navigate to "/users/sign_in"
    Then I should see "Log in"

  Scenario: Logging in with valid credentials
    Given I am a root user
    And I am logged in
    Then I should be logged in

  Scenario: Logging out
    Given I am logged in as a root user
    When I log out
    Then I should be logged out
