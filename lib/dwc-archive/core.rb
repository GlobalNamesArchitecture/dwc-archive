class DarwinCore
  class Core
    include DarwinCore::Ingester
    attr_reader :id 
    def initialize(dwc)
      @dwc = dwc
      @archive = @dwc.archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @data = @archive.meta[root_key][:core]
      raise DarwinCore::CoreFileError.new("Cannot find core in meta.xml, is meta.xml valid?") unless @data
      @id = @data[:id][:attributes] 
      # raise DarwinCore::CoreFileError.new("Cannot find core identifier") unless @id
      get_attributes(DarwinCore::CoreFileError)
    end
  end
end
