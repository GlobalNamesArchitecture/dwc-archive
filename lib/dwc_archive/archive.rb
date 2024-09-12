# frozen_string_literal: true

class DarwinCore
  # Deals with handling DarwinCoreArchive file, and provides meta information
  # and files information about archive
  class Archive
    attr_reader :meta, :eml

    def initialize(archive_path, tmp_dir)
      @archive_path = archive_path
      @tmp_dir = tmp_dir
      @expander = DarwinCore::Expander.new(@archive_path, @tmp_dir)
      @expander.unpack
      prepare_metadata
    end

    def valid?
      valid = true
      valid = valid && @expander.path && FileTest.exist?(@expander.path)
      valid && files && files.include?("meta.xml")
    end

    def files
      @expander.files
    end

    def files_path
      @expander.path
    end

    def clean
      @expander.clean
    end

    private

    def prepare_metadata
      if valid?
        prepare_meta_file
        prepare_eml_file
      else
        clean
        raise InvalidArchiveError
      end
    end

    def prepare_meta_file
      meta_file = File.open(File.join(@expander.path, "meta.xml"))
      @meta = DarwinCore::XmlReader.from_xml(meta_file)
    end

    def prepare_eml_file
      @eml = nil
      return unless files.include?("eml.xml")

      eml_file = File.open(File.join(@expander.path, "eml.xml"))
      @eml = DarwinCore::XmlReader.from_xml(eml_file)
    end
  end
end
