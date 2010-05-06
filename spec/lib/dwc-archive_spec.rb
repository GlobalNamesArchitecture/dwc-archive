require File.dirname(__FILE__) + "/../spec_helper"

describe DarwinCore do
  before(:all) do
    @file_dir = File.join(File.dirname(__FILE__), '..', 'files')
  end

  describe ".new" do 

    it "should create DarwinCore instance out of archive file" do
      ['data.zip', 'data.tar.gz', 'minimal.tar.gz'].each do |file|
        file = File.join(@file_dir, file)
        dwc = DarwinCore.new(file)
        dwc.archive.valid?.should be_true
      end
    end

    it "should raise error if archive file does not exist" do
      file = 'not_a_file'
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::FileNotFoundError)
    end

    it "should raise  error if archive is broken" do
      file = File.join(@file_dir, 'broken.tar.gz')
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::UnpackingError)
    end

    it "should raise error if archive is invalid" do
      file = File.join(@file_dir, 'invalid.tar.gz')
      lambda { DarwinCore.new(file) }.should raise_error(DarwinCore::InvalidArchiveError)
    end

    it "should work with files that have non-alfanumeric characters and spaces" do
      file = File.join(@file_dir, 'file with characters(3).gz')
      dwc = DarwinCore.new(file)
      dwc.archive.valid?.should be_true
    end

  end
end
