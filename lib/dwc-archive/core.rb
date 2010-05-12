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
      file = @core[:location] || @core[:attributes][:location] || @core[:files][:location]
      File.join(@path, file)
    end

    def id
      @core[:id][:attributes]
    end

    def fields
      @core[:field] = Array(@core[:field])
      @core[:field].map {|f| f[:attributes]}
    end

    def read(check_encoding = false)
      debugger
      f = open(file_path)
    end
    
  end
end
