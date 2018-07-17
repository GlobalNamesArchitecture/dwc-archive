# frozen_string_literal: true

describe DarwinCore::Metadata do
  subject(:eml) { DarwinCore::Metadata.new(dwca.archive) }
  let(:dwca) { DarwinCore.new(file_path) }
  let(:file_path) do
    File.join(File.expand_path("../files", __dir__), file_name)
  end
  let(:file_name) { "data.tar.gz" }

  describe ".new" do
    it "initializes" do
      expect(eml).to be_kind_of DarwinCore::Metadata
    end
  end

  describe "#data" do
    it "returns hash of metadata" do
      expect(eml.data).to be_kind_of Hash
    end
  end

  describe "#id" do
    it "returns id of the archive if it exists" do
      expect(eml.id).to eq "leptogastrinae:version:2.5"
    end
  end

  describe "#package_id" do
    context "no package id is given" do
      before(:example) do
        @attributes = eml.data[:eml].delete(:attributes)
      end

      after(:example) do
        eml.data[:eml][:attributes] = @attributes
      end

      it "returns id of the DwCA file if exists" do
        expect { eml.data[:eml][:attributes][:packageId] }.
          to raise_exception NoMethodError
        expect(eml.package_id).to be_nil
      end
    end
  end

  describe "#title" do
    it "returns name of the archive" do
      expect(eml.title).
        to eq "Leptogastrinae (Diptera: Asilidae) Classification"
    end
  end

  describe "#authors" do
    it "returns authors of the archive" do
      expect(eml.authors).
        to eq [
          { first_name: "Keith",
            last_name: "Bayless",
            email: "keith.bayless@gmail.com" },
          { first_name: "Torsten",
            last_name: "Dikow",
            email: "dshorthouse@eol.org" }
        ]
    end

    describe "#abstract" do
      it "returns abstract of an article" do
        expect(eml.abstract).
          to eq "These are all the names in the Leptogastrinae classification."
      end
    end

    describe "#citation" do
      it "returns citation of the archive" do
        expect(eml.citation).
          to eq "Dikow, Torsten. 2010. The Leptogastrinae classification."
      end
    end

    describe "#url" do
      it "returns url to the archive" do
        expect(eml.url).
          to eq "http://leptogastrinae.lifedesks.org/files/leptogastrinae/"\
                "classification_export/shared/leptogastrinae.tar.gz"
      end
    end
  end
end
