class DarwinCore
  # Represents core of the DarwinCore Archive
  class Core
    include DarwinCore::Ingester
    attr_reader :id

    def initialize(dwc)
      @dwc = dwc
      @archive = @dwc.archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @data = @archive.meta[root_key][:core]
      fail DarwinCore::CoreFileError,
           "Cannot find core in meta.xml, is meta.xml valid?" unless @data
      @id = @data[:id][:attributes]
      init_attributes
    end
  end
end
