class DarwinCore
  class Extension
    include DarwinCore::Ingester
    attr_reader :coreid
    alias :id :coreid

    def initialize(dwc, data)
      @dwc = dwc
      @archive = @dwc.archive
      @path = @archive.files_path
      @data = data
      @coreid = @data[:coreid][:attributes] 
      raise ExtensionFileError("Extension has no coreid information") unless @coreid
      get_attributes(ExtensionFileError)
    end

  end
end
