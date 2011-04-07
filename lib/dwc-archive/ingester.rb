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
      args.merge!({:quote_char => @quote_character}) if @quote_character != ''
      min_size = @fields.map {|f| f[:index].to_i || 0}.sort[-1] + 1
      CSV.open(@file_path, args).each_with_index do |r, i|
        index_fix = 0; next if @ignore_headers && i == 0
        min_size > r.size ? errors << r : process_csv_row(res, errors, r)
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
      if R19
        str = str.force_encoding('utf-8')
        str.encoding.name == "UTF-8" && str.valid_encoding? ? result << row : errors << row
      else
        require File.join(File.dirname(__FILE__), 'utf_regex_ruby18')
        UTF8RGX === str ? result << row : errors << row
      end
    end

    def get_attributes(exception)
      @properties = @data[:attributes]
      @encoding = @properties[:encoding] || 'UTF-8'
      raise exception("No support for encodings other than utf-8 or utf-16 at the moment") unless ["utf-8", "utf8", "utf-16", "utf16"].include? @encoding.downcase
      @field_separator = get_field_separator
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] ? [1, true].include?(@properties[:ignoreHeaderLines]) : false
      @file_path = get_file_path
      raise exception("No file data") unless @file_path
      @fields = get_fields
      raise exception("No data fields are found") if @fields.empty?
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
