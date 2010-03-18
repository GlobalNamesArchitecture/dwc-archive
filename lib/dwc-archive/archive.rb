require 'nokogiri'
class DarwinCore
  class Archive
    attr_reader :meta, :eml
    def initialize(archive_path, tmp_dir)
      @archive_path = archive_path
      @tmp_dir = tmp_dir
      @expander = DarwinCore::Expander.new(@archive_path, @tmp_dir)
      @expander.unpack
      if valid?
        @meta = Hash.from_xml(open(File.join(@expander.path, 'meta.xml')))
        @eml = files.include?("eml.xml") ? Hash.from_xml(open(File.join(@expander.path, 'eml.xml'))) : nil
      else
        clean
        raise 'not a valid Darwin Core Archive File'
      end
    end

    def valid?
      valid = true
      valid = valid && FileTest.exists?(@archive_path)
      valid = valid && files && files.include?('meta.xml')
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
