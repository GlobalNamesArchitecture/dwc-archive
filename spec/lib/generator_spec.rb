# frozen_string_literal: true

describe DarwinCore::Generator do
  subject(:gen) { DarwinCore::Generator.new(dwc_path, tmp_dir) }
  let(:tmp_dir) { DarwinCore::DEFAULT_TMP_DIR }
  let(:dwc_path) { File.join(tmp_dir, "spec_dwca.tar.gz") }

  def generate_dwca(gen)
    gen.add_core(CORE_DATA.dup, "core.csv", true)
    gen.add_extension(EXTENSION_DATA.dup, "vern.csv", true,
                      "http://rs.gbif.org/terms/1.0/VernacularName")
    gen.add_meta_xml
    gen.add_eml_xml(EML_DATA)
  end

  describe ".new" do
    it "initializes empty DwCA" do
      expect(gen).to be_kind_of DarwinCore::Generator
    end
  end

  describe "#add_core" do
    it "adds core to DwCA instance" do
      gen.add_core(CORE_DATA.dup, "core.csv", true)
      core = File.read(File.join(gen.path, "core.csv"))
      expect(core).to match(/taxonID,parentNameUsageID,scientificName/)
    end

    context "urls are not given in header" do
      it "raises error" do
        data = CORE_DATA.dup
        data[0] = data[0].map { |f| f.split("/")[-1] }
        expect { gen.add_core(data, "core.csv", true) }.
          to raise_error DarwinCore::GeneratorError
      end
    end
  end

  describe "#add_extension" do
    it "adds extension to DwCA instance" do
      gen.add_extension(EXTENSION_DATA.dup,
                        "vern.csv",
                        true,
                        "http://rs.gbif.org/terms/1.0/VernacularName")
      extension = File.read(File.join(gen.path, "vern.csv"))

      expect(extension).to match(/Береза/)
    end
  end

  describe "#add_meta_xml" do
    it "creates metadata for DwCA" do
      gen.add_core(CORE_DATA.dup, "core.csv", true)
      gen.add_extension(EXTENSION_DATA.dup,
                        "vern.csv",
                        true,
                        "http://rs.gbif.org/terms/1.0/VernacularName")

      gen.add_meta_xml
      meta = File.read(File.join(gen.path, "meta.xml")).strip
      meta_from_file = File.read(
        File.expand_path("../files/generator_meta.xml", __dir__)
      ).strip
      expect(meta).to eq meta_from_file
    end
  end

  describe "#add_eml_data" do
    it "adds eml data" do
      gen.add_eml_xml(EML_DATA)
      eml = File.read(File.join(gen.path, "eml.xml")).strip
      eml.gsub!(%r{(<pubDate>).*?(</pubDate>)}, '\12013-12-30 14:45:33 -0500\2')
      eml.gsub!(/(packageId=").*?"/, '\11234/2013-12-30::19:45:33"')

      eml_from_file = File.read(
        File.expand_path("../files/generator_eml.xml", __dir__)
      ).strip
      expect(eml.strip).to eq eml_from_file.strip
    end
  end

  describe "#path" do
    it "returns temporary path for assembling DwCA" do
      expect(gen.path).to match(/dwc_\d+$/)
    end
  end

  describe "#files" do
    before(:example) { generate_dwca(gen) }

    it "returns created files" do
      expect(gen.files).
        to match_array ["core.csv", "eml.xml", "meta.xml", "vern.csv"]
    end
  end

  describe "#pack" do
    before(:example) do
      FileUtils.rm dwc_path if File.exist?(dwc_path)
      generate_dwca(gen)
    end

    it "creates final DwCA file" do
      gen.pack
      expect(File.exist?(dwc_path)).to be true
    end
  end

  describe "#clean" do
    before(:example) { gen.add_eml_xml(EML_DATA) }

    it "removes temporary directory for DwCA" do
      expect(File.exist?(gen.path)).to be true
      gen.clean
      expect(File.exist?(gen.path)).to be false
    end
  end

  describe "#eml_xml_data" do
    it "returns current eml data" do
      expect(gen.eml_xml_data).to be_kind_of Hash
    end
  end
end
