class DarwinCore
  module Ingester
    attr_reader :data, :properties, :encoding, :fields_separator
    attr_reader :file_path, :fields, :line_separator, :quote_character, :ignore_headers
    def read(batch_size = 10000)
      res = []
      errors = []
      index_fix = 1
      args = {:col_sep => @field_separator}
      args.merge!({:quote_char => @quote_character}) if @quote_character != ''
      CSV.open(@file_path, args).each_with_index do |r, i|
        index_fix = 0; next if @ignore_headers && i == 0
        str = r.join('')
        if defined? FasterCSV
          UTF8RGX === str ? res << r : errors << r
        else
          str = str.force_encoding('utf-8')
          str.encoding.name == "UTF-8" && str.valid_encoding? ? res << r : errors << r
        end
        if block_given? && (i + index_fix) % batch_size == 0
          yield [res, errors]
          res = []
          errors = []
        end
      end
      [res, errors]
    end
    
    private
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
  end
end
