class DarwinCore
  class Core
    attr_reader :core, :id, :properties, :encoding, :fields_separator
    attr_reader :file_path, :fields, :line_separator, :quote_character, :ignore_headers
    alias :data :core
  
    def initialize(archive)
      @archive = archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @core = @archive.meta[root_key][:core]
      raise CoreFileError("Cannot found core in meta.xml, is meta.xml valid?") unless @core
      @properties = @core[:attributes]
      @encoding = @properties[:encoding] || 'UTF-8'
      raise CoreFileError("No support for encodings other than utf-8 or utf-16 at the moment") unless ["utf-8", "utf8", "utf-16", "utf16"].include? @encoding.downcase
      @id = @core[:id][:attributes]
      @field_separator = get_field_separator
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] ? ["1", "true"].include?(properties[:ignoreHeaderLines]) : false
      @file_path = get_file_path
      @fields = get_fields
    end

    def read(check_encoding = false, batch_size = 10000)
      debugger
      res = []
      args = {col_sep:@field_separator}
      args.merge!({quote_char:@quote_character}) if @quote_character != ''
      CSV.open(open(@file_path), args).each do |r|
        str = r.join('').force_encoding('utf-8')
        str.encoding.name == "UTF-8" && str.valid_encoding? ? res << r : puts("#{r} is wrong")
      end
      res
    end
    
    private
    def get_file_path
      file = @core[:location] || @core[:attributes][:location] || @core[:files][:location]
      File.join(@path, file)
    end

    def get_fields
      @core[:field] = Array(@core[:field]) 
      @core[:field].map {|f| f[:attributes]}
    end

    def get_field_separator
      res = @properties[:fieldsTerminatedBy] || ','
      res = "\t" if res == "\\t"
      res
    end
    
  end
end
