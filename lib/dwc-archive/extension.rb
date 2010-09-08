class DarwinCore
  class Extension
    include DarwinCore::Ingester
    attr_reader :coreid
    alias :id :coreid

    def initialize(archive, data)
      @archive = archive
      @path = @archive.files_path
      @data = data
      @coreid = @data[:coreid][:attributes] 
      raise ExtensionFileError("Extension has no coreid information") unless @coreid
      get_attributes(ExtensionFileError)
    end

  end
end
