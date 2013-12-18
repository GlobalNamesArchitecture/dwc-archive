describe DarwinCore::XmlReader do 
  
  describe '.from_xml' do

    it "reads xml to hash" do
      file = File.expand_path('../../files/meta.xml', __FILE__)
      meta = subject.from_xml(File.read(file))
      expect(meta.is_a? Hash).to be_true
      expect(meta[:archive].keys.sort).to eq [:core, :extension]
      expect(meta[:archive][:core].keys.sort).
        to eq [:attributes, :field, :files, :id]
    end

  end

end
