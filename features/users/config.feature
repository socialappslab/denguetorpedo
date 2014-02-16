Background: An account is setup and I'm logged in
Given I have an account with the following:
     | first_name      | Andrew       |
     | last_name       | TEST         |
     | phone_numer     | 1234567890   |
     | password        | andrewTest   |
And I'm on the "configuration" page


@javascript
Scenario: If I click edit/editar the name edit window should appear
  When I press "Editar"
  Then I should see the "name_edit_box"