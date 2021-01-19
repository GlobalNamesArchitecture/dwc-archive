# frozen_string_literal: true

describe DarwinCore::GnubTaxon do
  subject(:dwca) { DarwinCore.new(file_path) }
  subject(:normalizer) { DarwinCore::ClassificationNormalizer.new(dwca) }
  let(:file_dir) { File.expand_path("../files", __dir__) }
  let(:file_path) { File.join(file_dir, file_name) }
  let(:file_name) { "gnub.tar.gz" }

  it "should get uuids from GNUB" do
    normalizer.normalize
    tn = normalizer.normalized_data["9c399f90-cfb8-5a7f-9a21-18285a473488"]
    expect(tn).to be_kind_of DarwinCore::GnubTaxon
    expect(tn).to be_kind_of DarwinCore::TaxonNormalized
    expect(tn.uuid).to eq "8faa91f6-663f-4cfe-b785-0ab4e9415a51"
    expect(tn.uuid_path).to eq %w[
      9a9f9eeb-d5f9-4ff6-b6cb-a5ad345e33c3
      bf4c91c0-3d1f-44c7-9d3b-249382182a26
      8faa91f6-663f-4cfe-b785-0ab4e9415a51
    ]
  end

  context "not a gnub data" do
    let(:file_name) { "data.tar.gz" }
    it "should not be of GnubTaxon type" do
      normalizer.normalize
      tn = normalizer.normalized_data["leptogastrinae:tid:42"]
      expect(tn).to be_kind_of DarwinCore::TaxonNormalized
      expect(tn).not_to be_kind_of DarwinCore::GnubTaxon
    end
  end
end
