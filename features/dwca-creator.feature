Feature: Creating and writing a Darwin Core Archive
  In order to communicate with DwCA compatible programs
  A User should be able to
  Save data from ruby objects into Darwin Core Archive file

  Scenario: Creating Core File
    Given an array of urls for Darwin Core or other terms
    And arrays of data in the order correpsonding to order of terms
    When User sends this data 
    Then these data should be saved as darwin_core.txt file
