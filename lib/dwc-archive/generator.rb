class DarwinCore
  class Generator
    attr_reader :eml_xml_data

    #TODO refactor -- for now copying expander methods
    def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
      @dwc_path = dwc_path
      @path = File.join(tmp_dir, 'dwc_' + rand(10000000000).to_s)
      FileUtils.mkdir(@path)
      @meta_xml_data = {:extensions => []}
      @eml_xml_data = {:id => nil, :title => nil, :authors => [], :abstract => nil, :citation => nil, :url => nil}
      @write = R19 ? 'w:utf-8' : 'w'
    end
    
    #TODO refactor!
    def clean
      FileUtils.rm_rf(@path) if FileTest.exists?(@path)
    end

    def add_core(data, file_name, keep_headers = true)
      c = CSV.open(File.join(@path,file_name), @write)
      header = data.shift
      fields = header.map do |f|
        f.strip!
        raise GeneratorError("No header in core data, or header fields are not urls") unless f.match(/^http:\/\//)
        f.split("/")[-1]
      end
      data.unshift(fields) if keep_headers
      @meta_xml_data[:core] = {:fields => header, :ignoreHeaderLines => keep_headers, :location => file_name}
      data.each {|d| c << d}
      c.close
    end

    def add_extension(data, file_name, keep_headers = true)
      c = CSV.open(File.join(@path,file_name), @write)
      header = data.shift
      fields = header.map do |f|
        f.strip!
        raise GeneratorError("No header in core data, or header fields are not urls") unless f.match(/^http:\/\//)
        f.split("/")[-1]
      end
      data.unshift(fields) if keep_headers
      @meta_xml_data[:extensions] << { :fields => header, :ignoreHeaderLines => keep_headers, :location => file_name }
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
  end
end
