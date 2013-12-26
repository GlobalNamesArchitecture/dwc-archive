require_relative '../spec_helper'
# encoding: utf-8

describe DarwinCore::TaxonNormalized do
  subject(:dwca) { DarwinCore.new(file_path) }
  subject(:normalizer) { DarwinCore::ClassificationNormalizer.new(dwca) }
  let(:file_dir) { File.expand_path('../../files', __FILE__) }

  context 'typical case' do
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }
    let(:normalized) { normalizer.normalize }
    let(:tn) { normalized['leptogastrinae:tid:2681'] }

    it 'has TaxonNormalized type' do
      expect(tn).to be_kind_of DarwinCore::TaxonNormalized
    end

    describe '#id' do
      it 'returns taxon_id' do
        expect(tn.id).to eq 'leptogastrinae:tid:2681'
      end
    end

    describe '#local_id' do
      it 'returns local id' do
        expect(tn.id).to eq 'leptogastrinae:tid:2681'
      end
    end

    describe '#global_id' do
      it 'returns global id' do
        expect(tn.global_id).to eq '843ff0df-4bcd-4aad-ba94-643f8695a292'
      end
    end

    describe '#source' do
      it 'returns url to the data' do
        expect(tn.source).
          to eq 'http://leptogastrinae.lifedesks.org/pages/2681'
      end
    end 

    describe '#parent_id' do
      it 'returns ancestor\'s id' do
        expect(tn.parent_id).to eq 'leptogastrinae:tid:2584'
      end
    end
      
    describe '#classification_path_id' do
      it 'returns an array' do
        expect(tn.classification_path_id).to be_kind_of Array
      end

      it 'returns ids of classification path elements' do
        expect(tn.classification_path_id).
          to eq ['leptogastrinae:tid:42', 
                 'leptogastrinae:tid:2045', 
                 'leptogastrinae:tid:2584', 
                 'leptogastrinae:tid:2681']
      end
    end

    describe '#classification_path' do
      let(:cp) { tn.classification_path }
      it 'returns array of name strings of the classification path' do
        expect(cp).to be_kind_of Array
        expect(cp).to eq ["Leptogastrinae", 
                          "Leptogastrini", 
                          "Leptogaster", 
                          "Leptogaster flavipes"] 
      end
    end

    describe '#linnean_classification_path' do
      it 'returns empty array for parent/child based classification' do
        expect(tn.linnean_classification_path).to be_kind_of Array
        expect(tn.linnean_classification_path).to be_empty
      end
    end

    describe '#current_name' do
      it 'returns name marked as currently valid for the taxon' do
        expect(tn.current_name).to eq 'Leptogaster flavipes Loew, 1862'
      end
    end
    
    describe '#current_name_canonical' do
      it 'returns canonical form of valid name' do
        expect(tn.current_name_canonical).to eq 'Leptogaster flavipes'
      end
    end

    describe '#synonyms' do
      it 'returns array of sysnonyms' do
        expect(tn.synonyms).to be_kind_of Array
        synonym = tn.synonyms[0]
        expect(synonym).to be_kind_of DarwinCore::SynonymNormalized
        expect(synonym).to be_kind_of Struct
      end
    end

    describe '#vernacular_names' do
      context 'no vernacular names' do
        it 'returns empty array' do
          expect(tn.vernacular_names).to be_kind_of Array
          expect(tn.vernacular_names).to be_empty
        end
      end
    end

    describe '#rank' do
      it 'returns rank of the taxon' do
        expect(tn.rank).to eq 'species'
      end
    end

    describe '#status' do
      it 'returns status of taxon' do
        expect(tn.status).to be_nil
      end
    end
  end

end
