Feature: Reading of a Darwing Core Archive
  In order to start working with Darwin Core Archive file
  A user should be able initiate dwc object from a file
  So I want to implement handling of dwc object creation

  Scenario: Creating Darwin Core Archive object
    Given path to a dwc file "data.tar.gz"
    When I create a new DarwinCore::Archive instance
    Then I should find that the archive is valid 
    Then I should see what files the archive has

    When I delete expanded files
    Then they should disappear

  Scenario: Instantiating DarwinCore with a file without "eml.xml"
    Given path to a dwc file "minimal.tar.gz"
    When I create a new DarwinCore instance
    Then "DarwinCore_instance.metadata.data" should send instance of "NilClass" back

  Scenario: Instantiating DarwinCore with tar.gz file
    Given path to a dwc file "data.tar.gz"
    When I create a new DarwinCore instance 
    Then instance should have a valid archive
    And instance should have a core
    When I check core data
    Then I should find core.properties
    And core.file_path
    And core.id
    And core.fields
    Then DarwinCore instance should have an extensions array
    And every extension in array should be an instance of DarwinCore::Extension
    And extension should have properties, data, file_path, coreid, fields 
    Then DarwinCore instance should have dwc.metadata object
    And I should find id, title, creators, metadata provider

  Scenario: Instantiating DawinCore with zip file
    Given path to a dwc file "data.zip"
    When I create a new DarwinCore instance 
    Then instance should have a valid archive

  Scenario: Cleaning temporary directory from expanded archives
    Given acces to DarwinCore gem
    When I use DarwinCore.clean_all method
    Then all temporary directories created by DarwinCore are deleted

  Scenario: Importing data into memory
    Given path to a dwc file "data.tar.gz"
    When I create a new DarwinCore instance
    Then I can read its content into memory
    Then I can read extensions content into memory
  
  Scenario: Importing data using block
    Given path to a dwc file "data.tar.gz"
    When I create a new DarwinCore instance
    Then I can read its core content using block
    Then I can read extensions content using block

  Scenario: Normalizing classification
    Given path to a dwc file "data.tar.gz"
    When I create a new DarwinCore instance
    Then I am able to use DarwinCore#normalize_classification method
    And get normalized classification in expected format
    And there are paths, synonyms and vernacular names in normalized classification
    And names used in classification can be accessed by "name_strings" method
    And nodes_ids organized in trees can be accessed by "tree" method
