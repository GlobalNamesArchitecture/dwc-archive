require_relative '../spec_helper'
# encoding: utf-8

describe DarwinCore::ClassificationNormalizer do

  subject(:dwca) { DarwinCore.new(file_path) }
  subject(:normalizer) { DarwinCore::ClassificationNormalizer.new(dwca) }
  
  let(:file_dir) { File.expand_path('../../files', __FILE__) }

  describe '.new' do
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }
    it { expect(normalizer.is_a? DarwinCore::ClassificationNormalizer).
      to be_true }    
  end 
  describe "#normalize" do
    it "should return flat list if file has no parent id information" do
      file = File.join(file_dir, 'flat_list.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize

      cn.normalized_data.size.should > 0
    end

    it "should return array or hash of name_strings back" do
      file = File.join(file_dir, 'data.tar.gz')
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
      file = File.join(file_dir, 'data.tar.gz')
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
      file = File.join(file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      syn = norm.values.select {|n| n.synonyms.size > 0}[0].synonyms[0]
      syn.id.should == 'leptogastrinae:tid:127'
      syn.name.should == "Leptogastridae"
      syn.source.should == 'http://leptogastrinae.lifedesks.org/pages/127'
    end

    it "should be able to assemble vernacular names from an extension" do
      file = File.join(file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.vernacular_names.empty? }.map { |k,v| v.vernacular_names }.size.should > 0
    end

    it "should be able to assemble synonyms from extension" do
      file = File.join(file_dir, 'synonyms_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should > 0
    end

    it "should not assemble synonyms from extension with scientificName, and file name not matching 'synonym'" do
      file = File.join(file_dir, 'not_synonym_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should == 0
    end

    it "should not attempt to assemble extensions with with_extensions opts set to false" do
      file = File.join(file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize(:with_extensions => false)
      norm.select { |k,v| !v.vernacular_names.empty? }.size.should == 0
      norm = cn.normalize()
      norm.select { |k,v| !v.vernacular_names.empty? }.size.should > 0
      file = File.join(file_dir, 'synonyms_in_extension.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize(:with_extensions => false)
      norm.select { |k,v| !v.synonyms.empty? }.size.should == 0
      norm = cn.normalize()
      norm.select { |k,v| !v.synonyms.empty? }.size.should > 0
    end

    it "should assemble linnean classification if terms for it exists" do
      file = File.join(file_dir, 'linnean.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize
      cn.normalized_data.first.last.linnean_classification_path.should == [["Animalia", :kingdom], ["Arthropoda", :phylum], ["Insecta", :class], ["Diptera", :order], ["Cecidomyiidae", :family], ["Resseliella", :genus]]
    end

    it "should keep linnean classification empty if terms are not there" do
      file = File.join(file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      norm = cn.normalize
      cn.normalized_data.first.last.linnean_classification_path.should == []
    end

    it "should be able to assemble synonyms from core" do
      file = File.join(file_dir, 'synonyms_in_core_accepted_name_field.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      norm.select { |k,v| !v.synonyms.empty? }.map { |k,v| v.synonyms }.size.should > 0
    end

    it "should be able to assemble synonyms from extension" do
      file = File.join(file_dir, 'data.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      nodes_with_syn = norm.select { |k,v| !v.synonyms.empty? }
      nodes_with_syn.map { |k,v| v.synonyms }.size.should > 0
      nodes_with_syn.first[1].synonyms.first.status.should == 'synonym'
    end

    it "should be able work with files which have scientificNameAuthorship" do
      file = File.join(file_dir, 'sci_name_authorship.tar.gz')
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
      file = File.join(file_dir, 'sci_name_authorship_dup.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      taxa = norm.select{|k,v| v.current_name_canonical.match " "}.select{|k,v| [v.current_name.split(" ").size >  v.current_name_canonical.split(" ").size]}
      taxa.size.should == 507
      syn = norm.select{|k,v| v.synonyms.size > 0}.map {|k,v| v.synonyms}.flatten.select {|s| s.name.split(" ").size  > s.canonical_name.split(" ").size}
      syn.size.should == 50
    end

    it "should be able open files where coreid is empty" do
      file = File.join(file_dir, 'empty_coreid.tar.gz')
      dwc = DarwinCore.new(file)
      norm = dwc.normalize_classification
      taxa = norm.select{|k,v| v.current_name_canonical.match " "}.select{|k,v| [v.current_name.split(" ").size >  v.current_name_canonical.split(" ").size]}
      taxa.size.should == 2
    end

    it "should be able to get language and locality fields for vernacular names" do
      file = File.join(file_dir, 'language_locality.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize
      vn = cn.normalized_data['leptogastrinae:tid:42'].vernacular_names.first
      vn.language.should == 'en'
      vn.locality.should == 'New England'
    end

    it 'should be able to get uuids from gnub dataset' do
      file = File.join(file_dir, 'gnub.tar.gz')
      dwc = DarwinCore.new(file)
      cn = DarwinCore::ClassificationNormalizer.new(dwc)
      cn.normalize
      vn = cn.normalized_data['9c399f90-cfb8-5a7f-9a21-18285a473488']
      vn.class.should == DarwinCore::GnubTaxon
      vn.uuid.should == '8faa91f6-663f-4cfe-b785-0ab4e9415a51'
      vn.uuid_path.should == [
        "9a9f9eeb-d5f9-4ff6-b6cb-a5ad345e33c3",
        "bf4c91c0-3d1f-44c7-9d3b-249382182a26",
        "8faa91f6-663f-4cfe-b785-0ab4e9415a51"]
    end
  end

end
