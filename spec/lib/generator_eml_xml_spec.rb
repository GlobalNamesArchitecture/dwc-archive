describe DarwinCore::Generator::EmlXml do
  subject { DarwinCore::Generator::EmlXml.new(data, path) }
  let(:data) { EML_DATA }
  let(:path) { DarwinCore::DEFAULT_TMP_DIR }

  describe ".new" do
    it { is_expected.to be_kind_of DarwinCore::Generator::EmlXml }
  end

  describe "#create" do
    let(:content) do
      subject.create
      File.read(File.join(path, "eml.xml"))
    end

    it "should create eml xml" do
      expect(content).to match(/Test Classification/)
    end
  end
end
