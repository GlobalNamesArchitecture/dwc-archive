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
      if valid?
        @meta = DarwinCore::XmlReader.
                from_xml(open(File.join(@expander.path, "meta.xml")))
        @eml = nil
        if  files.include?("eml.xml")
          @eml = DarwinCore::XmlReader.
                 from_xml(open(File.join(@expander.path, "eml.xml")))
        end
      else
        clean
        fail InvalidArchiveError
      end
    end

    def valid?
      valid = true
      valid = valid && @expander.path && FileTest.exists?(@expander.path)
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
  end
end
