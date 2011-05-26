require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe DarwinCore do
  before(:all) do
    @file_dir = File.join(File.dirname(__FILE__), '..', 'files')
  end

  describe "VERSION" do
    it "should return VERSION number" do
      DarwinCore::VERSION.split('.').join('').to_i.should > 41
    end
  end

  describe "::nil_field?" do
    it "should return true for entries which normally mean nil" do
      [nil, '/N', ''].each do |i|
        DarwinCore.nil_field?(i).should be_true
      end
    end

    it "should return false for fields that are not nil" do
      [0, '0', '123', 123, 'dsdfs434343/N'].each do |i|
        DarwinCore.nil_field?(i).should be_false
      end
    end
  end

  describe ".new" do 
    it "should create DarwinCore instance out of archive file" do
      ['data.zip', 'data.tar.gz', 'minimal.tar.gz', 'junk_dir_inside.zip'].each do |file|
        file = File.join(@file_dir, file)
        dwc = DarwinCore.new(file)
        dwc.archive.valid?.should be_true
      end
    end

    it "should raise an error if archive file does not exist" do
      file = 'not_a_file'
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::FileNotFoundError)
    end

    it "should raise an error if archive is broken" do
      file = File.join(@file_dir, 'broken.tar.gz')
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::UnpackingError)
    end

    it "should raise an error if archive is invalid" do
      file = File.join(@file_dir, 'invalid.tar.gz')
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::InvalidArchiveError)
    end

    it "should work with files that have non-alfanumeric characters and spaces" do
      file = File.join(@file_dir, 'file with characters(3).gz')
      dwc = DarwinCore.new(file)
      dwc.archive.valid?.should be_true
    end
  end

  describe ".normalize_classification" do
    it "should return nil if file has no parent id information" do
      file = File.join(@file_dir, 'flat_list.tar.gz')
      dwc = DarwinCore.new(file)
      dwc.normalize_classification.should be_nil
    end
    
    it "should traverse DarwinCore files and assemble data for every node in memory" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.class.should == Hash
      norm['leptogastrinae:tid:2857'].class.should == DarwinCore::TaxonNormalized
    end

    it "should be able to assemble vernacular names from an extension" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.vernacular_names.empty? }.map { |k,v| v.vernacular_names }.size.should > 0
    end

    it "should be able to assemble synonyms from extension" do
      file = File.join(@file_dir, 'synonyms_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should > 0
    end
    
    it "should be able to assemble synonyms from extension" do
      file = File.join(@file_dir, 'synonyms_in_core_accepted_name_field.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should > 0
    end

    it "should be able to assemble synonyms from extension" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      nodes_with_syn = norm.select { |k,v| !v.synonyms.empty? }
      nodes_with_syn.map { |k,v| v.synonyms }.size.should > 0
      nodes_with_syn.first[1].synonyms.first.status.should == 'synonym'
    end

    it "should be able work with files which have scientificNameAuthorship" do
      file = File.join(@file_dir, 'sci_name_authorship.tar.gz')
      dwc = DarwinCore.new(file)
      $lala = 1
      norm = dwc.normalize_classification
      taxa = norm.select{|k,v| v.current_name_canonical.match " "}.select{|k,v| [v.current_name.split(" ").size >  v.current_name_canonical.split(" ").size]}
      taxa.size.should == 507
      syn = norm.select{|k,v| v.synonyms.size > 0}.map {|k,v| v.synonyms}.flatten.select {|s| s.name.split(" ").size  > s.canonical_name.split(" ").size}
      syn.size.should == 50
    end

    it "should be able to get language and locality fields for vernacular names" do
      file = File.join(@file_dir, 'language_locality.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize
      vn = cn.normalized_data['leptogastrinae:tid:42'].vernacular_names.first
      vn.language.should == 'en'
      vn.locality.should == 'New England'
    end
  end

end
