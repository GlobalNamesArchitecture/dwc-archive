describe DarwinCore::XmlReader do
  describe '.from_xml' do
    let(:file) { File.expand_path('../../files/meta.xml', __FILE__) }
    subject { DarwinCore::XmlReader.from_xml(File.read(file)) }

    it "reads xml to hash" do
      expect(subject).to be_kind_of Hash
      expect(subject[:archive].keys.sort).to eq [:core, :extension]
      expect(subject[:archive][:core].keys.sort).
        to eq [:attributes, :field, :files, :id]
    end

  end

end
