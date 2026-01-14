@admin @javascript
Feature: User Editing
  As an administrator
  I want to edit user accounts
  So that the right people have the correct access levels

  Background:
    Given I am logged in as a root user

  # Form Section Visibility
  Scenario: User edit form shows all sections
    Given there is a user called "Test User"
    When I edit the user "Test User"
    And I go to the "Permissions" step
    Then I should see "Partners"
    And I should see "Neighbourhoods"
    And I should see "Partnerships"
    When I go to the "Admin" step
    Then I should see "Role"

  Scenario: User form shows contact fields
    Given there is a user called "Contact Test User"
    When I edit the user "Contact Test User"
    Then I should see "First Name"
    And I should see "Last Name"
    And I should see "Email"
    And I should see "Phone"

  # Contact Information Fields
  Scenario: Updating user first name
    Given there is a user called "Name Update User"
    When I edit the user "Name Update User"
    And I fill in "First Name" with "Updated"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating user last name
    Given there is a user called "Last Name User"
    When I edit the user "Last Name User"
    And I fill in "Last Name" with "NewLastName"
    And I click the "Save" button
    Then I should see a success message

  Scenario: Updating user phone
    Given there is a user called "Phone User"
    When I edit the user "Phone User"
    And I fill in "Phone" with "0161 555 0000"
    And I click the "Save" button
    Then I should see a success message

  # Partner Assignment
  Scenario: User form shows partner assignment
    Given there is a user called "Partner Assignment User"
    And there is a partner called "Riverside Community Hub"
    When I edit the user "Partner Assignment User"
    And I go to the "Permissions" step
    Then I should see "Partners"
    And I should see "Partners this user can edit"

  Scenario: User form shows partner drop down
    Given there is a user called "Partner Drop Down User"
    And there is a partner called "Assignable Partner"
    When I edit the user "Partner Drop Down User"
    And I go to the "Permissions" step
    Then I should see "Assignable Partner"

  # Neighbourhood Assignment (Root Only)
  Scenario: Root user can see neighbourhood assignment
    Given there is a user called "Neighbourhood User"
    And there is a neighbourhood called "Central Ward"
    When I edit the user "Neighbourhood User"
    And I go to the "Permissions" step
    Then I should see "Neighbourhoods"
    And I should see "Grants access to every partner"

  Scenario: User form shows neighbourhood drop down
    Given there is a user called "Ward User"
    And there is a neighbourhood called "Riverside Ward"
    When I edit the user "Ward User"
    And I go to the "Permissions" step
    Then I should see "Riverside Ward"

  # Partnership/Tag Assignment
  Scenario: User form shows partnership assignment
    Given there is a user called "Tag User"
    And there is a partnership tag called "Millbrook Together"
    When I edit the user "Tag User"
    And I go to the "Permissions" step
    Then I should see "Partnerships"
    And I should see "Grants access to add or remove partners from partnerships"

  Scenario: User form shows partnership drop down
    Given there is a user called "Partnership User"
    And there is a partnership tag called "Coastal Alliance"
    When I edit the user "Partnership User"
    And I go to the "Permissions" step
    Then I should see "Coastal Alliance"

  # Role Selection
  Scenario: User form shows role selection
    Given there is a user called "Role Test User"
    When I edit the user "Role Test User"
    And I go to the "Admin" step
    Then I should see "Role"
