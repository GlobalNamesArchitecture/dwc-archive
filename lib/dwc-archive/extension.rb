class DarwinCore
  class Extension
    def initialize(archive, extension)
      @archive = archive
      @path = @archive.files_path
      @extension = extension
    end

    def data
      @extension
    end

    def properties
      @extension[:attributes]
    end
    
    def file_path
      file = @extension[:files][:location] 
      File.join(@path, file)
    end

    def coreid
      @extension[:coreid][:attributes]
    end

    def fields
      @extension[:field] = [@extension[:field]] unless @extension[:field].class == Array
      @extension[:field].map {|f| f[:attributes]}
    end
  end
end
