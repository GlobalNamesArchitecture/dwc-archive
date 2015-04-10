describe DarwinCore::Generator::MetaXml do
  subject { DarwinCore::Generator::MetaXml.new(data, path) }
  let(:data) { META_DATA }
  let(:path) { DarwinCore::DEFAULT_TMP_DIR }

  describe ".new" do
    it { is_expected.to be_kind_of DarwinCore::Generator::MetaXml }
  end

  describe "#create" do
    let(:content) do
      subject.create
      File.read(File.join(path, "meta.xml"))
    end

    it "creates metadata file" do
      expect(content).to match(%r{<location>core.csv</location>})
    end
  end
end
