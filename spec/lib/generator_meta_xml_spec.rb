require_relative '../spec_helper'

describe DarwinCore::Generator::MetaXml do
  subject(:meta) { DarwinCore::Generator::MetaXml.new(data, path) }
  let(:data) { META_DATA }
  let(:path) { DarwinCore::DEFAULT_TMP_DIR }

  describe '.new' do
    it 'initializes' do
      expect(meta).to be_kind_of DarwinCore::Generator::MetaXml
    end
  end

  describe '#create' do
    it 'creates metadata file' do
      meta.create
      meta = File.read(File.join(path, 'meta.xml'))
      expect(meta).to match %r|<location>core.csv</location>|  
    end
  end
end
