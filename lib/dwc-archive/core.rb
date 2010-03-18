class DarwinCore
  class Core
    def initialize(archive)
      @archive = archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @core = @archive.meta[root_key][:core]
      raise "Cannot found core in meta.xml, is meta.xml valid?" unless @core
    end

    def data
      @core
    end

    def properties
      @core[:attributes]
    end

    def file_path
      file = @core[:files][:location] || @core[:location]
      File.join(@path, file)
    end

    def id
      @core[:id][:attributes]
    end

    def fields
      @core[:field] = [@core[:field]] unless @core[:field].class == Array
      @core[:field].map {|f| f[:attributes]}
    end
    
  end
end
