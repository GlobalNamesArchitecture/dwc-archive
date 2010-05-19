class DarwinCore
  class Core
    include DarwinCore::Ingester
    attr_reader :id 
    def initialize(archive)
      @archive = archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @data = @archive.meta[root_key][:core]
      raise CoreFileError("Cannot found core in meta.xml, is meta.xml valid?") unless @data
      @properties = @data[:attributes]
      @encoding = @properties[:encoding] || 'UTF-8'
      raise CoreFileError("No support for encodings other than utf-8 or utf-16 at the moment") unless ["utf-8", "utf8", "utf-16", "utf16"].include? @encoding.downcase
      @id = @data[:id][:attributes]
      @field_separator = get_field_separator
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] ? [1, true].include?(@properties[:ignoreHeaderLines]) : false
      @file_path = get_file_path
      @fields = get_fields
    end
  end
end
