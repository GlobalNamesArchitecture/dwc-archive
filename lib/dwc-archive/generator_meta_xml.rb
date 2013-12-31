class DarwinCore
  class Generator
    class MetaXml
      def initialize(data, path)
        @data = data
        @path = path
        @write = 'w:utf-8'
      end

      def create
        schema_uri =  'http://rs.tdwg.org/dwc/terms/xsd/archive/' + 
          ' http://darwincore.googlecode.com/svn/trunk/text/tdwg_dwc_text.xsd'
        builder = Nokogiri::XML::Builder.new do |xml|
          opts = { encoding: 'UTF-8', 
                   fieldsTerminatedBy: ',', 
                   fieldsEnclosedBy: '"', 
                   linesTerminatedBy: "\n", 
                   rowType: 'http://rs.tdwg.org/dwc/terms/Taxon' }
          build_archive(xml, opts, schema_uri)
        end
        meta_xml_data = builder.to_xml
        meta_file = open(File.join(@path, 'meta.xml'), @write)
        meta_file.write(meta_xml_data)
        meta_file.close
      end

      private
      
      def build_archive(xml, opts, schema_uri)
        xml.archive(xmlns: 'http://rs.tdwg.org/dwc/text/',
          :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          :'xsi:schemaLocation' => schema_uri) do
          build_core(xml, opts)
          build_extensions(xml, opts)
        end
      end

      def build_core(xml, opts)
        xml.core(opts.merge(ignoreHeaderLines: 
                              @data[:core][:ignoreHeaderLines])) do
          xml.files { xml.location(@data[:core][:location]) }
          taxon_id, fields = find_taxon_id(@data[:core][:fields])
          xml.id_(index: taxon_id[1])
          fields.each { |f| xml.field(term: f[0], index: f[1]) }
        end
      end

      def build_extensions(xml, opts)
        @data[:extensions].each do |e|
          xml.extension(opts.merge(ignoreHeaderLines: e[:ignoreHeaderLines], 
                                   rowType: e[:rowType])) do
            xml.files { xml.location(e[:location]) }
            taxon_id, fields = find_taxon_id(e[:fields])
            xml.coreid(index: taxon_id[1])
            fields.each { |f| xml.field(term: f[0], index: f[1]) }
          end
        end
      end

      def find_taxon_id(data)
        fields = []
        data.each_with_index { |f, i| fields << [f.strip, i] }
        taxon_id, fields = fields.partition { |f| f[0].match(%r|/taxonid$|i) }
        raise DarwinCore::GeneratorError if taxon_id.size != 1
        [taxon_id[0], fields]
      end

    end
  end
end

