# encoding: utf-8
class DarwinCore
  # This module abstracts information for reading csv file to be used
  # in several classes which need such functionality
  module Ingester
    attr_reader :data, :properties, :encoding, :fields_separator, :size
    attr_reader :file_path, :fields, :line_separator, :quote_character,
                :ignore_headers

    def size
      @size ||= init_size
    end

    def read(batch_size = 10_000)
      DarwinCore.logger_write(@dwc.object_id, "Reading #{name} data")
      res = []
      errors = []
      args = define_csv_args
      min_size = @fields.map { |f| f[:index].to_i || 0 }.sort[-1] + 1
      csv = CSV.new(open(@file_path), args)
      csv.each_with_index do |r, i|
        next if @ignore_headers && i == 0
        min_size > r.size ? errors << r : process_csv_row(res, errors, r)
        next if i == 0 || i % batch_size != 0
        DarwinCore.logger_write(@dwc.object_id,
                                format("Ingested %s records from %s",
                                       i, name))
        next unless block_given?
        yield [res, errors]
        res = []
        errors = []
      end
      yield [res, errors] if block_given?
      [res, errors]
    end

    private

    def define_csv_args
      args = { col_sep: @field_separator }
      @quote_character = "\b" if @quote_character.empty?
      args.merge(quote_char: @quote_character)
    end

    def name
      self.class.to_s.split("::")[-1].downcase
    end

    def process_csv_row(result, errors, row)
      str = row.join("")
      str = str.force_encoding("utf-8")
      if str.encoding.name == "UTF-8" && str.valid_encoding?
        result << row.map { |f| f.nil? ? nil : f.force_encoding("utf-8") }
      else
        errors << row
      end
    end

    def init_attributes
      @properties = @data[:attributes]
      init_encoding
      @field_separator = init_field_separator
      @quote_character = @properties[:fieldsEnclosedBy] || ""
      @line_separator = @properties[:linesTerminatedBy] || "\n"
      @ignore_headers = @properties[:ignoreHeaderLines] &&
                        [1, true].include?(@properties[:ignoreHeaderLines])
      init_file_path
      init_fields
    end

    def init_encoding
      @encoding = @properties[:encoding] || "UTF-8"
      accepted_encoding = ["utf-8", "utf8", "utf-16", "utf16"].
                          include?(@encoding.downcase)
      fail(
        DarwinCore::EncodingError,
        "No support for encodings other than utf-8 or utf-16 at the moment"
      ) unless accepted_encoding
    end

    def init_file_path
      file = @data[:location] ||
             @data[:attributes][:location] ||
             @data[:files][:location]
      @file_path = File.join(@path, file)
      fail DarwinCore::FileNotFoundError, "No file data" unless @file_path
    end

    def init_fields
      @data[:field] = [data[:field]] if data[:field].class != Array
      @fields = @data[:field].map { |f| f[:attributes] }
      fail DarwinCore::InvalidArchiveError,
           "No data fields are found" if @fields.empty?
    end

    def init_field_separator
      res = @properties[:fieldsTerminatedBy] || ","
      res = "\t" if res == "\\t"
      res
    end

    def init_size
      `wc -l #{@file_path}`.match(/^\s*([\d]+)\s/)[1].to_i
    end
  end
end
