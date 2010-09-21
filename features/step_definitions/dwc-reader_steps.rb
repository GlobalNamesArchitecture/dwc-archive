require 'ruby-debug'

Given /^path to a dwc file "([^\"]*)"$/ do |arg1|
  @dwca_file = File.expand_path(File.dirname(__FILE__) + "../../../spec/files/" + arg1)
  @tmp_dir = "/tmp"
end

When /^I create a new DarwinCore::Archive instance$/ do
  @dwca = DarwinCore::Archive.new(@dwca_file, @tmp_dir)
end

Then /^I should find that the archive is valid$/ do
  @dwca.valid?.should be_true
end

Then /^I should see what files the archive has$/ do
  @dwca.files.should == ["DarwinCore.txt", "VernacularName.txt", "eml.xml", "leptogastrinae.xlsx", "meta.xml", "metadata.txt"]
end

When /^I delete expanded files$/ do
  @dwca.clean
end

Then /^they should disappear$/ do
  @dwca.files.should be_nil
end

When /^I create a new DarwinCore instance$/ do
  begin
    @dwc = DarwinCore.new(@dwca_file)
  rescue
    @dwca_broken_file = @dwca_file
    @dwc_error = $!
  end
end

Then /^instance should have a valid archive$/ do
  @dwc.archive.valid?.should be_true
end

Then /^instance should have a core$/ do
  @dwc.core.class.should == DarwinCore::Core
end

When /^I check core data$/ do
  @core = @dwc.core
end

Then /^I should find core.properties$/ do
  @core.properties.class.should == Hash
  @core.properties[:encoding].should == "UTF-8"
  @core.properties[:fieldsTerminatedBy].should == "\\t"
  @core.properties[:linesTerminatedBy].should == "\\n"
end

And /^core\.file_path$/ do
  @core.file_path.should match(/\/tmp\/dwc_[\d]+\/DarwinCore.txt/)
end

And /^core\.id$/ do
  @core.id.should == {:index => 0, :term => 'http://rs.tdwg.org/dwc/terms/TaxonID'}
end

And /^core\.fields$/ do
  @core.fields.size.should == 5
end
Then /^DarwinCore instance should have dwc\.metadata object$/ do
  @dwc.metadata.class.should == DarwinCore::Metadata
end

And /^I should find id, title, creators, metadata provider$/ do
  @dwc.metadata.id.should == 'leptogastrinae:version:2.5'
  @dwc.metadata.title.should == 'Leptogastrinae (Diptera: Asilidae) Classification'
  @dwc.metadata.authors.should == [
      {:last_name=>"Bayless", :email=>"keith.bayless@gmail.com", :first_name=>"Keith"},
      {:last_name=>"Dikow", :email=>"dshorthouse@eol.org", :first_name=>"Torsten"}]
  @dwc.metadata.abstract.should == 'These are all the names in the Leptogastrinae classification.'
  @dwc.metadata.citation.should == 'Dikow, Torsten. 2010. The Leptogastrinae classification.'
  @dwc.metadata.url.should == 'http://leptogastrinae.lifedesks.org/files/leptogastrinae/classification_export/shared/leptogastrinae.tar.gz'
end

Then /^DarwinCore instance should have an extensions array$/ do
  @dwc.extensions.class.should == Array
  @dwc.extensions.size.should == 1
end

And /^every extension in array should be an instance of DarwinCore::Extension$/ do
  classes = @dwc.extensions.map {|e| e.class}.uniq
  classes.size.should == 1
  classes[0].should == DarwinCore::Extension
end

Then /^extension should have properties, data, file_path, coreid, fields$/ do
  ext = @dwc.extensions[0]
  ext.properties.should == {:ignoreHeaderLines=>1, :encoding=>"UTF-8", :rowType=>"http://rs.gbif.org/ipt/terms/1.0/VernacularName", :fieldsEnclosedBy=>"", :fieldsTerminatedBy=>"\\t", :linesTerminatedBy=>"\\n"}
  ext.data.class.should == Hash
  ext.file_path.should match(/\/tmp\/dwc_[\d]+\/VernacularName.txt/)
  ext.coreid.should == {:index=>0}
  ext.fields.should == [{:term=>"http://rs.gbif.org/ecat/terms/vernacularName", :index=>1}, {:term=>"http://rs.gbif.org/thesaurus/languageCode", :index=>2}]
end

Given /^acces to DarwinCore gem$/ do
end

When /^I use DarwinCore\.clean_all method$/ do
  Dir.entries("/tmp").select {|e| e.match(/^dwc_/) }.size.should > 0
  DarwinCore.clean_all
end

Then /^all temporary directories created by DarwinCore are deleted$/ do
  Dir.entries("/tmp").select {|e| e.match(/^dwc_/) }.should == []
end

Then /^I receive "([^\"]*)" exception with "([^\"]*)" message$/ do |arg1, arg2|
   @dwc_error.class.to_s.should == arg1
   @dwc_error.message.should == arg2
   @dwca_broken_file.should == @dwca_file
   @dwc_error = nil
   @dwca_broken_file = nil
end

Then /^"([^\"]*)" should send instance of "([^\"]*)" back$/ do |arg1, arg2|
  res = eval(arg1.gsub(/DarwinCore_instance/, "@dwc"))
  res.class.to_s.should == arg2
end

Then /^I can read its content into memory$/ do
  core_data, core_errors = @dwc.core.read
  core_data.class.should == Array
  core_data.size.should == 584
  core_errors.size.should == 3
end

Then /^I can read extensions content into memory$/ do
  ext = @dwc.extensions
  ext.class.should == Array
  ext_data, ext_errors = ext[0].read
  ext_data.class.should == Array
  ext_data.size.should == 1
  ext_errors.size.should == 0
end

Then /^I can read its core content using block$/ do
  res = []
  @dwc.core.ignore_headers.should be_true
  tail_data, tail_errors = @dwc.core.read(200) do |r, err|
    res << [r.size, err.size]
  end
  res << [tail_data.size, tail_errors.size]
  res.should == [[198,2],[200,0],[186,1]]
end

Then /^I can read extensions content using block$/ do
  res = []
  ext = @dwc.extensions[0]
  ext.ignore_headers.should be_true
  tail_data, tail_errors = ext.read(200) do |r, err|
    res << [r.size, err.size]
  end
  res << [tail_data.size, tail_errors.size]
  res.should == [[1,0]]
end

Then /^I am able to use DarwinCore\#normalize_classification method$/ do
  @cn = DarwinCore::ClassificationNormalizer.new(@dwc)
  @normalized_classification = @cn.normalize
end

Then /^get normalized classification in expected format$/ do
  @normalized_classification.class.should == Hash
  key = @normalized_classification.keys[0]
  @normalized_classification[key].class.should == DarwinCore::TaxonNormalized
end

Then /^there are paths, synonyms and vernacular names in normalized classification$/ do
  @paths_are_generated = false
  @synonyms_are_generated = false
  @vernaculars_are_generated = false
  @normalized_classification.each do |k, v|
    if v.classification_path.size > 0
      @paths_are_generated = true
    end
    if v.synonyms.size > 0
      @synonyms_are_generated = true
    end
    if v.vernacular_names.size > 0
      @vernaculars_are_generated = true
    end
    break if (@vernaculars_are_generated && @paths_are_generated && @synonyms_are_generated)
  end
  @paths_are_generated.should be_true
  @vernaculars_are_generated.should be_true
  @synonyms_are_generated.should be_true
end

Then /^names used in classification can be accessed by "([^"]*)" method$/ do |name_strings|
  names = @cn.send(name_strings.to_sym) 
  names.size.should > @normalized_classification.size
end


Then /^nodes_ids organized in trees can be accessed by "([^"]*)" method$/ do |tree|
  def flatten_tree(data, keys)
    data.each do |k, v|
      keys << k
      if v != {}
        debugger if v.class != Hash
        flatten_tree(v, keys)
      end
    end
  end
  tree = @cn.send(tree.to_sym)
  tree.class.should == Hash
  keys = []
  flatten_tree(tree, keys) 
  @normalized_classification.size.should == keys.size
end

