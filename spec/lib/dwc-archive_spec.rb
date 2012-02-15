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
    it "should return flat list if file has no parent id information" do
      file = File.join(@file_dir, 'flat_list.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize
      cn.normalized_data.should_not be_nil
      cn.normalized_data.size.should > 0
    end

    it "should return array or hash of name_strings back" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize
      name_strings = cn.name_strings
      name_strings.is_a?(Array).should be_true
      name_strings.size.should > 1
      name_strings = cn.name_strings(with_hash: true)
      name_strings.size.should > 1
      name_strings.is_a?(Hash).should be_true
      name_strings.is_a?(Hash).should be_true
      name_strings.values.uniq.should == [1]
      vernacular_name_strings = cn.vernacular_name_strings
      vernacular_name_strings.is_a?(Array).should be_true
      vernacular_name_strings.size.should > 0
      vernacular_name_strings = cn.vernacular_name_strings(with_hash: true)
      vernacular_name_strings.size.should > 0
      vernacular_name_strings.is_a?(Hash).should be_true
      vernacular_name_strings.values.uniq.should == [1]
    end

    it "should traverse DarwinCore files and assemble data for every node in memory" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.class.should == Hash
      path_encodings = []
      norm.each do |taxon_id, taxon|
        taxon.classification_path.each {|p| path_encodings << p.encoding}
      end
      path_encodings.uniq!
      path_encodings.size.should == 1
      path_encodings[0].to_s.should == "UTF-8"
      norm['leptogastrinae:tid:2857'].class.should == DarwinCore::TaxonNormalized
      norm['leptogastrinae:tid:2857'].source.should == 'http://leptogastrinae.lifedesks.org/pages/2857'
    end

    it "should assemble synonyms from core" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      syn = norm.values.select {|n| n.synonyms.size > 0}[0].synonyms[0]
      syn.id.should == 'leptogastrinae:tid:127'
      syn.name.should == "Leptogastridae"
      syn.source.should == 'http://leptogastrinae.lifedesks.org/pages/127'
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

    it "should not assemble synonyms from extension with scientificName, and file name not matching 'synonym'" do
      file = File.join(@file_dir, 'not_synonym_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should == 0
    end

    it "should not attempt to assemble extensions with with_extensions opts set to false" do
      file = File.join(@file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize(:with_extensions => false)
      norm.select { |k,v| !v.vernacular_names.empty? }.size.should == 0
      norm = cn.normalize()
      norm.select { |k,v| !v.vernacular_names.empty? }.size.should > 0
      file = File.join(@file_dir, 'synonyms_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize(:with_extensions => false)
      norm.select { |k,v| !v.synonyms.empty? }.size.should == 0
      norm = cn.normalize()
      norm.select { |k,v| !v.synonyms.empty? }.size.should > 0
    end

    it "should be able to assemble synonyms from core" do
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
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize
      path_encodings = norm.map {|taxon_id, taxon| taxon.classification_path}.flatten.map { |name| name.encoding.to_s }.uniq
      path_encodings.size.should == 1
      path_encodings[0].should == "UTF-8"
      taxa = norm.select{|k,v| v.current_name_canonical.match " "}.select{|k,v| [v.current_name.split(" ").size >  v.current_name_canonical.split(" ").size]}
      taxa.size.should == 507
      syn = norm.select{|k,v| v.synonyms.size > 0}.map {|k,v| v.synonyms}.flatten.select {|s| s.name.split(" ").size  > s.canonical_name.split(" ").size}
      syn.size.should == 50
    end

    it "should be able work with files which repeat scientificNameAuthorship value in scientificName field" do
      file = File.join(@file_dir, 'sci_name_authorship_dup.tar.gz')
      dwc = DarwinCore.new(file)
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
