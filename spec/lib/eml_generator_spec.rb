require_relative '../spec_helper'

describe DarwinCore::Generator::EmlXml do
  subject(:eml) { DarwinCore::Generator::EmlXml.new(data, path) }
  let(:data) { EML_DATA }
  let(:path) { DarwinCore::DEFAULT_TMP_DIR }

  describe '.new' do
    it 'initializes generator' do
      expect(eml).to be_kind_of DarwinCore::Generator::EmlXml
    end
  end

  describe '#create' do
    it 'should create eml xml' do
      eml.create
      eml_xml = File.read(File.join(path, 'eml.xml'))
      expect(eml_xml).to match /Test Classification/
    end
  end
end
