#encoding: utf-8
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

When /^User sends this data to core generator$/ do
  @data = @data.unshift @rows
  @gen.add_core(@data, 'darwin_core.txt')
end

Then /^these data should be saved as "([^\"]*)" file$/ do |file_name|
  file = File.join(@gen.path, file_name)
  @gen.files.include?(file_name).should be_true
  csv = CSV.open(file).count.should == 4
end

Given /^2 sets of data with terms as urls in the header$/ do
  @vernaculars = [
      ["http://rs.tdwg.org/dwc/terms/TaxonID", "http://rs.tdwg.org/dwc/terms/vernacularName"],
      [1, "Plants"],
      [1, "Растения"],
      [2, "Birch"],
      [2, "Береза"],
      [3, "Wheeping Birch"],
      [3, "Береза плакучая"]
    ]
  @synonyms = [
      ["http://rs.tdwg.org/dwc/terms/TaxonID", "http://rs.tdwg.org/dwc/terms/scientificName", "http://rs.tdwg.org/dwc/terms/taxonomicStatus"], 
      [1, "Betila Linnaeus, 1753", 'misspelling']
    ]
end

When /^User creates generator$/ do
  @gen = DarwinCore::Generator.new('/tmp/dwc.tar.gz')
end

When /^User adds extensions with file names "([^\"]*)" and "([^\"]*)"$/ do |file_name_1, file_name_2|
  @gen.add_extension(@vernaculars, file_name_1)
  @gen.add_extension(@synonyms, file_name_2)
end

Then /^data are saved as "([^\"]*)" and "([^\"]*)"$/ do |file_name_1, file_name_2|
  [file_name_1, file_name_2].each do |file_name|
    file = File.join(@gen.path, file_name)
    @gen.files.include?(file_name).should be_true
    csv = CSV.open(file).count.should > 1
  end
end

When /^User generates meta\.xml and eml.xml$/ do
  @gen.add_meta_xml
  @gen.add_eml_xml({
    :id => '1234',
    :title => 'Test Classification',
    :authors => [
      { :first_name => 'John',
        :last_name => 'Doe',
        :email => 'jdoe@example.com' },
      { :first_name => 'Jane',
        :last_name => 'Doe', 
        :email => 'jane@example.com' }
      ],
    :abstract => 'test classification',
    :citation => 'Test classification: Doe John, Doe Jane, Taxnonmy, 10, 1, 2010',
    :url => 'http://example.com'
  })
end

Then /^there should be "([^\"]*)" file with core and extensions informations$/ do |file_name|
  meta = File.join(@gen.path, file_name)
  @gen.files.include?(file_name).should be_true
  dom = Nokogiri::XML(open(File.join(@gen.path, file_name)))
  dom.xpath('//xmlns:core//xmlns:location').text.should == 'darwin_core.txt'
  dom.xpath('//xmlns:extension[1]//xmlns:location').text.should == 'vernacular.txt'
end

Then /^there should be "([^\"]*)" file with authoriship information$/ do |file_name|
  eml = File.join(@gen.path, file_name)
  @gen.files.include?(file_name).should be_true
end

Given /^a path to a new file \- "([^\"]*)"$/ do |file_name|
  @dwca_file = file_name
end

When /^generates archive$/ do
  @gen.pack
end

Then /^there should be a valid new archive file$/ do
  dwc = DarwinCore.new('/tmp/dwc.tar.gz')
  dwc.archive.valid?.should be_true
end

