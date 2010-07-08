class DarwinCore
  class Core
    include DarwinCore::Ingester
    attr_reader :id 
    def initialize(archive)
      @archive = archive
      debugger
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @data = @archive.meta[root_key][:core]
      raise CoreFileError("Cannot found core in meta.xml, is meta.xml valid?") unless @data
      @id = @data[:id][:attributes]
      raise CoreFileError("Cannot find core identifier") unless @id
      get_attributes(CoreFileError)
    end
  end
end
