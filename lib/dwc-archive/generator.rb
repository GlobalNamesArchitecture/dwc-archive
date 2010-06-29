class DarwinCore
  class Generator
    #TODO refactor -- for now copying expander methods
    def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
      @dwc_path = dwc_path
      @path = File.join(tmp_dir, 'dwc_gen_' + rand(10000000000).to_s)
      FileUtils.mkdir(@path)
      @meta_xml_data = {:extensions => []}
      @eml_xml_data = {}
    end
    
    #TODO refactor!
    def clean
      FileUtils.rm_rf(@path) if FileTest.exists?(@path)
    end

    def core=(data, keep_headers = true)
      c = CSV.open(File.join(@path, "dwc_archive.txt"), 'w:utf-8')
      header = data.shift
      fields = header.map do |f|
        f.strip!
        raise GeneratorError("No header in core data, or header fields are not urls") unless f.match(/^http:\/\//)
        f.split("/")[-1]
      end
      data.unshift(fields) if keep_headers
      debugger
      @meta_xml_data[:core] = {:fields => header, :ignoreHeaderLines => keep_headers}
      data.each {|d| c << d}
      c.close
    end

    def path
      @path
    end
    
    def files
      return nil unless @path && FileTest.exists?(@path)
      Dir.entries(@path).select {|e| e !~ /[\.]{1,2}$/}.sort
    end


  end
end
