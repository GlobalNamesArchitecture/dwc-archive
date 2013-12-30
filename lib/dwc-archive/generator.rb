class DarwinCore
  class Generator
    attr_reader :eml_xml_data

    #TODO refactor -- for now copying expander methods
    def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
      @dwc_path = dwc_path
      @path = File.join(tmp_dir, 'dwc_' + rand(10000000000).to_s)
      FileUtils.mkdir(@path)
      @meta_xml_data = {:extensions => []}
      @eml_xml_data = {:id => nil, :title => nil, 
        :authors => [], :abstract => nil, :citation => nil, :url => nil}
      @write = 'w:utf-8'
    end
    
    #TODO refactor!
    def clean
      FileUtils.rm_rf(@path) if FileTest.exists?(@path)
    end

    def add_core(data, file_name, keep_headers = true)
      c = CSV.open(File.join(@path,file_name), @write)
      header = data.shift
      fields = get_fields(header, 'core') 
      data.unshift(fields) if keep_headers
      ignore_header_lines = keep_headers ? 1 : 0
      @meta_xml_data[:core] = { fields: header, 
                                ignoreHeaderLines: ignore_header_lines, 
                                location:file_name }
      data.each {|d| c << d}
      c.close
    end

    def add_extension(data, file_name, 
                      keep_headers = true, 
                      row_type = 'http://rs.tdwg.org/dwc/terms/Taxon')
      c = CSV.open(File.join(@path,file_name), @write)
      header = data.shift
      fields = get_fields(header, 'extension')
      data.unshift(fields) if keep_headers
      ignore_header_lines = keep_headers ? 1 : 0
      @meta_xml_data[:extensions] << { fields: header, 
                                       ignoreHeaderLines: ignore_header_lines, 
                                       location: file_name, 
                                       rowType: row_type }
      data.each { |d| c << d }
      c.close
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

    def path
      @path
    end
    
    def files
      return nil unless @path && FileTest.exists?(@path)
      Dir.entries(@path).select {|e| e !~ /[\.]{1,2}$/}.sort
    end

    def pack
      a = "cd #{@path}; tar -zcf #{@dwc_path} *"
      system(a)
    end

    private

    def get_fields(header, file_type)
      header.map do |f|
        f.strip!
        err = "No header in %s data, or header fields are not urls" % file_type
        raise DarwinCore::GeneratorError.new(err) unless f.match(/^http:\/\//)
        f.split('/')[-1]
      end
    end
  end
end
