Feature: Create Reports
	In order to earn points
	As an reporter
	I want to identify and eliminate mosquito breathing sites

	Scenario: Reports List
		Given I have reports for Rua Tatajuba 50, Rua Sargent Silva Nunes 1012
		When I go to the list of reports
		Then I should see "Rua Tatajuba 50"
		And I should see "Rua Sargent Silva Nunes 1012"