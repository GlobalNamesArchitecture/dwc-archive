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
      get_attributes(DarwinCore::ExtensionFileError)
    end

  end
end
