# encoding: utf-8
require "coveralls"
Coveralls.wear!

require "dwc_archive"
require "rspec"
require "rspec/mocks"
require "socket"

RSpec.configure do
end

unless defined?(SPEC_CONSTANTS)
  EML_DATA =
    {
      id: "1234",
      license: "http://creativecommons.org/licenses/by-sa/3.0/",
      title: "Test Classification",
      authors: [
        { first_name: "John",
          last_name: "Doe",
          email: "jdoe@example.com",
          organization: "Example",
          position: "Assistant Professor",
          url: "http://example.org" },
        { first_name: "Jane",
          last_name: "Doe",
          email: "jane@example.com" }
      ],
      metadata_providers: [
        { first_name: "Jim",
          last_name: "Doe",
          email: "jimdoe@example.com",
          url: "http://aggregator.example.org" }
      ],
      abstract: "test classification",
      citation:
        "Test classification: Doe John, Doe Jane, Taxnonmy, 10, 1, 2010",
      url: "http://example.com"
    }
  META_DATA = {
    extensions:
      [
        { fields:
            [
              "http://rs.tdwg.org/dwc/terms/TaxonID",
              "http://rs.tdwg.org/dwc/terms/vernacularName"
            ],
          ignoreHeaderLines: 1,
          location: "vern.csv",
          rowType: "http://rs.gbif.org/terms/1.0/VernacularName" }
      ],
    core: { fields:
              [
                "http://rs.tdwg.org/dwc/terms/taxonID",
                "http://rs.tdwg.org/dwc/terms/parentNameUsageID",
                "http://rs.tdwg.org/dwc/terms/scientificName",
                "http://rs.tdwg.org/dwc/terms/taxonRank"
              ],
            ignoreHeaderLines: 1,
            location: "core.csv" } }
  CORE_DATA = [
    ["http://rs.tdwg.org/dwc/terms/taxonID",
     "http://rs.tdwg.org/dwc/terms/parentNameUsageID",
     "http://rs.tdwg.org/dwc/terms/scientificName",
     "http://rs.tdwg.org/dwc/terms/taxonRank"],
    [1, 0, "Plantae", "kingdom"],
    [2, 1, "Betula", "genus"],
    [3, 2, "Betula verucosa", "species"]
  ]
  EXTENSION_DATA = [
    ["http://rs.tdwg.org/dwc/terms/TaxonID",
     "http://rs.tdwg.org/dwc/terms/vernacularName"],
    [1, "Plants"],
    [1, "Растения"],
    [2, "Birch"],
    [2, "Береза"],
    [3, "Wheeping Birch"],
    [3, "Береза плакучая"]
  ]
  SPEC_CONSTANTS = true
end
