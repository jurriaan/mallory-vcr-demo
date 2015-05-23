Feature: Example
  @vcr
  Scenario: Some example to demonstrate the use of VCR with external programs
    When the client does an external GET request to "https://www.google.nl" 
    Then the response should include "Google"
