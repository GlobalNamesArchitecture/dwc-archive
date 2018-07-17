# frozen_string_literal: true

class DarwinCore
  # Creates csv files for core and extensions
  class Generator
    attr_reader :eml_xml_data, :path

    def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
      @dwc_path = dwc_path
      @path = DarwinCore.random_path(tmp_dir)
      FileUtils.mkdir(@path)
      @meta_xml_data = { extensions: [] }
      @eml_xml_data = { id: nil, title: nil, authors: [], abstrac: nil,
                        citation: nil, url: nil }
      @write = "w:utf-8"
    end

    def clean
      DarwinCore.clean(@path)
    end

    def add_core(data, file_name, keep_headers = true)
      opts = { type: "core", data: data, file_name: file_name,
               keep_headers: keep_headers }
      prepare_csv_file(opts)
    end

    def add_extension(data, file_name, keep_headers = true,
                      row_type = "http://rs.tdwg.org/dwc/terms/Taxon")
      opts = { type: "extension", data: data, file_name: file_name,
               keep_headers: keep_headers, row_type: row_type }
      prepare_csv_file(opts)
    end

    def add_meta_xml
      meta = DarwinCore::Generator::MetaXml.new(@meta_xml_data, @path)
      meta.create
    end

    def add_eml_xml(data)
      @eml_xml_data = data
      eml = DarwinCore::Generator::EmlXml.new(@eml_xml_data, @path)
      eml.create
    end

    def files
      DarwinCore.files(@path)
    end

    def pack
      a = "cd #{@path}; tar -zcf #{@dwc_path} *"
      system(a)
    end

    private

    def prepare_csv_file(opts)
      c = CSV.open(File.join(@path, opts[:file_name]), @write)
      attributes = prepare_attributes(opts)
      if opts[:type] == "core"
        @meta_xml_data[:core] = attributes
      else
        @meta_xml_data[:extensions] << attributes
      end
      opts[:data].each { |d| c << d }
      c.close
    end

    def prepare_attributes(opts)
      header = opts[:data].shift
      fields = init_fields(header, opts[:type])
      opts[:data].unshift(fields) if opts[:keep_headers]
      ignore_header_lines = opts[:keep_headers] ? 1 : 0

      res = { fields: header, ignoreHeaderLines: ignore_header_lines,
              location: opts[:file_name] }
      res[:rowType] = opts[:row_type] if opts[:row_type]
      res
    end

    def init_fields(header, file_type)
      header.map do |f|
        f = f.strip
        err = "No header in #{file_type} data, or header fields are not urls"
        raise DarwinCore::GeneratorError, err unless f =~ %r{^http://}
        f.split("/")[-1]
      end
    end
  end
end
