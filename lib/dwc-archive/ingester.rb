# encoding: utf-8
class DarwinCore
  module Ingester
    attr_reader :data, :properties, :encoding, :fields_separator, :size
    attr_reader :file_path, :fields, :line_separator, :quote_character, :ignore_headers

    def size
      @size ||= get_size
    end

    def read(batch_size = 10000)
      DarwinCore.logger_write(@dwc.object_id, "Reading %s data" % name)
      res = []
      errors = []
      index_fix = 1
      args = {:col_sep => @field_separator}
      @quote_character = "\b" if @quote_character.empty?
      args.merge!({:quote_char => @quote_character})
      min_size = @fields.map {|f| f[:index].to_i || 0}.sort[-1] + 1
      open(@file_path).each_with_index do |line, i|
        index_fix = 0; next if @ignore_headers && i == 0
        begin 
          row = CSV.parse(line, args)[0]
          if min_size > row.size
            errors << row
          else
            res << row.map { |f| f.nil? ? nil : f.force_encoding('utf-8') }
          end
        rescue ArgumentError
          line.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '?')
          line.encode!('UTF-8', 'UTF-16')
          row = CSV.parse(line, args)[0]
          errors << row
        end
        if (i + index_fix) % batch_size == 0
          DarwinCore.logger_write(@dwc.object_id, "Ingested %s records from %s" % [(i + index_fix), name])
          if block_given?
            yield [res, errors]
            res = []
            errors = []
          end
        end
      end
      yield [res, errors] if block_given?
      [res, errors]
    end

    private
    def name
      self.class.to_s.split('::')[-1].downcase
    end

    def process_csv_row(result, errors, row)
      str = row.join('')
      str = str.force_encoding('utf-8')
      str.encoding.name == "UTF-8" && str.valid_encoding? ? result << row.map { |f| f.nil? ? nil : f.force_encoding('utf-8') } : errors << row
    end

    def get_attributes(exception)
      @properties = @data[:attributes]
      @encoding = @properties[:encoding] || 'UTF-8'
      raise DarwinCore::EncodingError.new("No support for encodings other than utf-8 or utf-16 at the moment") unless ["utf-8", "utf8", "utf-16", "utf16"].include? @encoding.downcase
      @field_separator = get_field_separator
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] ? [1, true].include?(@properties[:ignoreHeaderLines]) : false
      @file_path = get_file_path
      raise DarwinCore::FileNotFoundError.new("No file data") unless @file_path
      @fields = get_fields
      raise DarwinCore::InvalidArchiveError.new("No data fields are found") if @fields.empty?
    end

    def get_file_path
      file = @data[:location] || @data[:attributes][:location] || @data[:files][:location]
      File.join(@path, file)
    end

    def get_fields
      @data[:field] = [data[:field]] if data[:field].class != Array
      @data[:field].map {|f| f[:attributes]}
    end

    def get_field_separator
      res = @properties[:fieldsTerminatedBy] || ','
      res = "\t" if res == "\\t"
      res
    end

    def get_size
      `wc -l #{@file_path}`.match(/^\s*([\d]+)\s/)[1].to_i
    end
  end
end
