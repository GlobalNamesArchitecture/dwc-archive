Feature: Creating and writing a Darwin Core Archive
  In order to communicate with DwCA compatible programs
  A User should be able to
  Save data from ruby objects into Darwin Core Archive file

  Scenario: Creating Core File
    Given an array of urls for Darwin Core or other terms
    And arrays of data in the order correpsonding to order of terms
    When User creates generator
    And User sends this data to core generator
    Then these data should be saved as "darwin_core.txt" file

  Scenario: Creating Extensions
    Given 2 sets of data with terms as urls in the header
    When User creates generator
    And User adds extensions with file names "vernacular.txt" and "synonyms.txt"
    Then data are saved as "vernacular.txt" and "synonyms.txt"

  Scenario: Creating metadata.xml and eml.xml
    Given an array of urls for Darwin Core or other terms
    And arrays of data in the order correpsonding to order of terms
    And 2 sets of data with terms as urls in the header
    When User creates generator
    And User sends this data to core generator
    And User adds extensions with file names "vernacular.txt" and "synonyms.txt"
    And User generates meta.xml and eml.xml
    Then there should be "meta.xml" file with core and extensions informations
    And there should be "eml.xml" file with authoriship information

  Scenario: Making DarwinCore Archive file
    Given an array of urls for Darwin Core or other terms
    And arrays of data in the order correpsonding to order of terms
    And 2 sets of data with terms as urls in the header
    When User creates generator
    And User sends this data to core generator
    And User adds extensions with file names "vernacular.txt" and "synonyms.txt"
    And User generates meta.xml and eml.xml
    And generates archive
    Then there should be a valid new archive file

