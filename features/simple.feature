Feature: Simple feature
  In order to work out how capybara works
  As a user
  I want to see if I can see the home page

  Scenario: Looking at the home page
    Given I am on the home page 
    Then I should see "NI Subscription app"
