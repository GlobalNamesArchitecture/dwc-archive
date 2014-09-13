class DarwinCore
  # Represents extensions of DarwinCore Archive
  class Extension
    include DarwinCore::Ingester
    attr_reader :coreid
    alias_method :id, :coreid

    def initialize(dwc, data)
      @dwc = dwc
      @archive = @dwc.archive
      @path = @archive.files_path
      @data = data
      @coreid = @data[:coreid][:attributes]
      init_attributes
    end
  end
end
