# encoding: utf-8

describe DarwinCore::ClassificationNormalizer do
  subject(:dwca) { DarwinCore.new(file_path) }
  subject(:normalizer) { DarwinCore::ClassificationNormalizer.new(dwca) }

  let(:file_dir) { File.expand_path("../../files", __FILE__) }
  let(:file_path) { File.join(file_dir, file_name) }

  describe ".new" do
    let(:file_path) { File.join(file_dir, "data.tar.gz") }
    it do
      expect(normalizer.is_a? DarwinCore::ClassificationNormalizer).to be true
    end
  end

  describe "#normalize" do
    let(:file_name) { "data.tar.gz" }

    it "returns normalized data" do
      res = normalizer.normalize
      expect(res).to be normalizer.normalized_data
    end

    context "flat list" do
      let(:file_path) { File.join(file_dir, "flat_list.tar.gz") }

      it "returns flat list" do
        normalizer.normalize
        expect(normalizer.normalized_data).to be_kind_of Hash
        expect(normalizer.normalized_data.size).to be > 0
      end
    end

    context "synonyms from core" do
      let(:file_name) { "synonyms_in_core_accepted_name_field.tar.gz" }

      it "ingests synonyms using accepted_name field" do
        res = normalizer.normalize
        syn = res.select { |_, v| !v.synonyms.empty? }.values
        expect(syn.size).to be > 0
        expect(syn[0].synonyms[0]).to be_kind_of DarwinCore::SynonymNormalized
      end
    end

    context "synonyms from extension" do
      let(:file_name) { "synonyms_in_extension.tar.gz" }
      it "ingests synonyms from extension" do
        res = normalizer.normalize
        syn = res.select { |_, v| !v.synonyms.empty? }.values
        expect(syn.size).to be > 0
        expect(syn[0].synonyms[0]).to be_kind_of DarwinCore::SynonymNormalized
      end
    end

    context "synonyms are not extensions" do
      let(:file_name) { "not_synonym_in_extension.tar.gz" }

      it "does not ingest synonyms" do
        res = normalizer.normalize
        syn = res.select { |_, v| !v.synonyms.empty? }.values
        expect(syn).to be_empty
      end
    end

    context "with_extensions flag set on false" do
      let(:file_name) { "synonyms_in_extension.tar.gz" }
      it "should not harvest extensions" do
        res = normalizer.normalize(with_extensions: false)
        syn = res.select { |_, v| !v.synonyms.empty? }.values
        expect(syn).to be_empty
      end
    end

    context "linnean classification in file (class, order etc fields)" do
      let(:file_name) { "linnean.tar.gz" }

      it "assembles classification" do
        res = normalizer.normalize
        expect(res.first[1]).to be_kind_of DarwinCore::TaxonNormalized
        expect(res.first[1].linnean_classification_path).
          to eq [["Animalia", :kingdom],
                 ["Arthropoda", :phylum],
                 ["Insecta", :class],
                 ["Diptera", :order],
                 ["Cecidomyiidae", :family],
                 ["Resseliella", :genus]]
      end
    end

    context "no linnean fields are given" do
      it "returns empty linnean classification" do
        res = normalizer.normalize
        expect(res.first[1]).to be_kind_of DarwinCore::TaxonNormalized
        expect(res.first[1].linnean_classification_path).to be_empty
      end
    end

    context "in the presence of scientificNameAuthorship field" do
      let(:file_name) { "sci_name_authorship.tar.gz" }
      it "returns normalized data" do
        normalizer.normalize
        expect(normalizer.darwin_core.file_name).
          to eq "sci_name_authorship.tar.gz"
        expect(normalizer.normalized_data).to be_kind_of Hash
        expect(normalizer.normalized_data.size).to be > 0
        tn = normalizer.normalized_data["leptogastrinae:tid:2688"]
        expect(tn.current_name).to eq "Leptogaster fornicata Martin, 1957"
        expect(tn.current_name_canonical).to eq "Leptogaster fornicata"
      end
    end

    context "when scientificNameAuthorship duplicates author info" do
      let(:file_name) { "sci_name_authorship_dup.tar.gz" }
      it "returns normalized data" do
        normalizer.normalize
        expect(normalizer.darwin_core.file_name).
          to eq "sci_name_authorship_dup.tar.gz"
        expect(normalizer.normalized_data).to be_kind_of Hash
        expect(normalizer.normalized_data.size).to be > 0
        tn = normalizer.normalized_data["leptogastrinae:tid:2688"]
        expect(tn.current_name).to eq "Leptogaster fornicata Martin, 1957"
        expect(tn.current_name_canonical).to eq "Leptogaster fornicata"
      end
    end

    context "coreid is empty" do
      let(:file_name) { "empty_coreid.tar.gz" }
      it "should ingest information" do
        res = normalizer.normalize
        expect(normalizer.darwin_core.file_name).
          to eq "empty_coreid.tar.gz"
        tn = res["Taxon9"]
        expect(tn.current_name).to eq "Amanita phalloides"
      end
    end

    context "vernacular locality info" do
      let(:file_name) { "language_locality.tar.gz" }
      it "should ingest locality and language" do
        res = normalizer.normalize
        tn = res["leptogastrinae:tid:42"]
        vn = tn.vernacular_names[0]
        expect(vn.language).to eq "en"
        expect(vn.locality).to eq "New England"
      end
    end
  end

  describe "#name_strings" do
    let(:file_path) { File.join(file_dir, "flat_list.tar.gz") }

    context "before running #normalize" do
      it "is empty" do
        expect(normalizer.name_strings).to be_empty
      end
    end

    context "after running #normalize" do
      let(:normalized) { normalizer.tap(&:normalize) }

      context "default attibutes" do
        it "returns array" do
          expect(normalized.name_strings).to be_kind_of Array
          expect(normalized.name_strings.size).to be > 1
        end
      end

      context "with_hash attribute" do
        it "returns hash" do
          strings = normalized.name_strings(with_hash: true)
          expect(strings).to be_kind_of Hash
          expect(strings.size).to be > 1
          expect(strings.values.uniq).to eq [1]
        end
      end
    end
  end

  describe "#vernacular_name_strings" do
    let(:file_path) { File.join(file_dir, "flat_list.tar.gz") }

    context "before running #normalize" do
      subject(:vern) { normalizer.vernacular_name_strings }

      it "is empty" do
        expect(vern).to be_empty
      end
    end

    context "after running #normalize" do
      let(:normalized) { normalizer.tap(&:normalize) }
      subject(:vern) { normalized.vernacular_name_strings }
      subject(:vern_w_hash) do
        normalized.vernacular_name_strings(with_hash: true)
      end

      context "default attibutes" do
        it "returns array" do
          expect(vern).to be_kind_of Array
          expect(vern.size).to be > 0
        end
      end

      context "with_hash attribute" do
        it "returns hash" do
          expect(vern_w_hash).to be_kind_of Hash
          expect(vern_w_hash.size).to be > 0
          expect(vern_w_hash.values.uniq).to eq [1]
        end
      end
    end
  end
end
