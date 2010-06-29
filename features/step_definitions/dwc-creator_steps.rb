require 'ruby-debug'

Given /^an array of urls for Darwin Core or other terms$/ do
  @rows = ["http://rs.tdwg.org/dwc/terms/taxonID", "http://rs.tdwg.org/dwc/terms/parentNameUsageID", "http://rs.tdwg.org/dwc/terms/scientificName", "http://rs.tdwg.org/dwc/terms/taxonRank"]
end

Given /^arrays of data in the order correpsonding to order of terms$/ do
  @data = [
      [1, 0, "Plantae", "kingdom"],
      [2, 1, "Betula", "genus"],
      [3, 2, "Betula verucosa", "species"]
  ]
end

When /^User sends this data$/ do
  @data = @data.unshift @rows
  @gen = DarwinCore::Generator.new('dwc.tar.gz')
  @gen.core = @data
end

Then /^these data should be saved as darwin_core\.txt file$/ do
  file = File.join(@gen.path, "darwin_core.txt")
  @gen.files.include?(file).should be_true
  CSV.open(file, 'r:utf-8')
end

