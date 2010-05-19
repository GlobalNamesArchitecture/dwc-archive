class DarwinCore
  class Extension
    include DarwinCore::Ingester
    attr_reader :coreid

    def initialize(archive, data)
      @archive = archive
      @path = @archive.files_path
      @data = data
      @properties = @data[:attributes]
      @coreid = @data[:coreid][:attributes]
      @encoding = @properties[:encoding] || 'UTF-8'
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] ? [1, true].include?(@properties[:ignoreHeaderLines]) : false
      @field_separator = get_field_separator
      @file_path = get_file_path
      @fields = get_fields
    end

  end
end
