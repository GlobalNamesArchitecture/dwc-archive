require_relative '../spec_helper'
# encoding: utf-8

describe DarwinCore::Generator do
  subject(:gen) { DarwinCore::Generator.new(dwc_path, tmp_dir) }
  let(:tmp_dir) { DarwinCore::DEFAULT_TMP_DIR }
  let(:dwc_path) { File.join(tmp_dir, 'spec_dwca.tar.gz') } 

  describe '.new' do
    it 'initializes empty DwCA' do
      expect(gen).to be_kind_of DarwinCore::Generator      
    end
  end

  describe '#add_core' do
    it 'adds core to DwCA instance' do
      gen.add_core(CORE_DATA.dup, 'core.csv', true)
      core = File.read(File.join(gen.path, 'core.csv'))
      expect(core).to match /taxonID,parentNameUsageID,scientificName/
    end

    context 'urls are not given in header' do
      it 'raises error' do
        data = CORE_DATA.dup
        data[0] = data[0].map { |f| f.split('/')[-1] }
        expect { gen.add_core(data, 'core.csv', true) }.
                              to raise_error DarwinCore::GeneratorError
      end
    end
  end

  describe '#add_extension' do
    it 'adds extension to DwCA instance' do
      gen.add_extension(EXTENSION_DATA.dup, 
                        'vern.csv', 
                        true, 
                        'http://rs.gbif.org/terms/1.0/VernacularName')
      extension = File.read(File.join(gen.path, 'vern.csv'))
      
      expect(extension).to match /Береза/
    end
  end

  describe '#add_meta_xml' do
    it 'creates metadata for DwCA' do
      gen.add_core(CORE_DATA.dup, 'core.csv', true)
      gen.add_extension(EXTENSION_DATA.dup, 
                        'vern.csv', 
                        true, 
                        'http://rs.gbif.org/terms/1.0/VernacularName')

      gen.add_meta_xml
      meta = File.read(File.join(gen.path, 'meta.xml'))
      expect(meta).to match %r|<location>core.csv</location>|
    end
  end

  describe '#add_eml_data' do
    it 'adds eml data' do
      gen.add_eml_xml(EML_DATA)
      eml = File.read(File.join(gen.path, 'eml.xml'))
      expect(eml).to match /jdoe@example.com/
    end
  end

  describe '#path' do
    it 'returns temporary path for assembling DwCA' do
      expect(gen.path).to match /dwc_\d+$/
    end
  end

  describe '#files' do
    it 'returns created files' do
      gen.add_core(CORE_DATA.dup, 'core.csv', true)
      gen.add_extension(EXTENSION_DATA.dup, 
                        'vern.csv', 
                        true, 
                        'http://rs.gbif.org/terms/1.0/VernacularName')

      gen.add_meta_xml
      expect(gen.files).to match_array ['core.csv', 'meta.xml', 'vern.csv']  
    end
  end

  describe '#pack' do
    it 'creates final DwCA file' do
      FileUtils.rm dwc_path if File.exists?(dwc_path)
      gen.add_core(CORE_DATA.dup, 'core.csv', true)
      gen.add_extension(EXTENSION_DATA.dup, 
                        'vern.csv', 
                        true, 
                        'http://rs.gbif.org/terms/1.0/VernacularName')

      gen.add_meta_xml
      gen.add_eml_xml(EML_DATA)
      gen.pack
      expect(File.exists?(dwc_path)).to be_true 
    end
  end

  describe '#clean' do
    it 'removes temporary directory for DwCA' do
      gen.add_eml_xml(EML_DATA)
      expect(File.exists?(gen.path)).to be true
      gen.clean
      expect(File.exists?(gen.path)).to be false
    end
  end

  describe '#eml_xml_data' do
    it 'returns current eml data' do
      expect(gen.eml_xml_data).to be_kind_of Hash
    end
  end
  
end
