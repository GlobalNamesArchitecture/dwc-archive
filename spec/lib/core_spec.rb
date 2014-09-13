require_relative "../spec_helper"

describe DarwinCore::Core do
  subject(:dwca) { DarwinCore.new(file_path) }
  subject(:core) { DarwinCore::Core.new(dwca) }
  let(:file_path) do
    File.join(File.expand_path("../../files", __FILE__), file_name)
  end
  let(:file_name) { "data.tar.gz" }

  describe ".new" do
    it "creates new core" do
      expect(core).to be_kind_of DarwinCore::Core
    end
  end

  describe "#id" do
    it "returns core id" do
      expect(core.id[:index]).to eq 0
      expect(core.id[:term]).to eq "http://rs.tdwg.org/dwc/terms/TaxonID"
    end

    context "no coreid" do
      let(:file_name) { "empty_coreid.tar.gz" }

      it "does not return coreid" do
        expect(core.id[:index]).to eq 0
        expect(core.id[:term]).to be_nil
      end
    end
  end

  describe "#data" do
    it "gers core data" do
      expect(core.data).to be_kind_of Hash
    end
  end

  describe "#properties" do
    it "gers core properties" do
      expect(core.properties).to be_kind_of Hash
      expect(core.properties.keys).to match_array [
        :encoding, :fieldsTerminatedBy, :linesTerminatedBy, :fieldsEnclosedBy,
        :ignoreHeaderLines, :rowType
      ]
    end
  end

  describe "#encoding" do
    it "returns encoding of the data" do
      expect(core.encoding).to eq "UTF-8"
    end
  end

  describe "#fields_separator" do
    it "returns separator of fields for csv files" do
      expect(core.fields_separator).to be_nil
    end
  end

  describe "#size" do
    it "returns number of lines in the core" do
      expect(core.size).to eq 588
    end
  end

  describe "#file_path" do
    it "returns file path of core file" do
      expect(core.file_path).to match "DarwinCore.txt"
    end
  end

  describe "#fields" do
    it "returns fields of the core file" do
      expect(core.fields.size).to eq 7
      expect(core.fields).to be_kind_of Array
      expect(core.fields[0]).to be_kind_of Hash
    end
  end

  describe "#line_separator" do
    it "returns characters separating lines in csv file" do
      expect(core.line_separator).to eq "\\n"
    end
  end

  describe "#quote_character" do
    it "returns quote character for the csv file" do
      expect(core.quote_character).to eq ""
    end
  end

  describe "#ignore headers" do
    it "returns true if headers should not be included into data" do
      expect(core.ignore_headers).to eq true
    end
  end
end
