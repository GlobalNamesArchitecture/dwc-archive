class DarwinCore
  class Generator
    class MetaXml
      def initialize(data, path)
        @data = data
        @path = path
        @write = R19 ? 'w:utf-8' : 'w'
      end

      def create
        builder = Nokogiri::XML::Builder.new do |xml|
          opts = { :encoding => "UTF-8", :fieldsTerminatedBy => ",", :fieldsEnclosedBy => '"', :linesTerminatedBy => "\n", :rowType => "http://rs.tdwg.org/dwc/tems/Taxon" }
          xml.starArchive(:xmlns => "http://rs.tdwg.org/dwc/terms/xsd/archive/",
            "xmlns:xsi" =>"http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation" => "http://rs.tdwg.org/dwc/terms/xsd/archive/ http://darwincore.googlecode.com/svn/trunk/text/tdwg_dwc_text.xsd",
            :fileRoot => ".") do
            xml.core(opts.merge(:ignoreHeaderLines => @data[:core][:ignoreHeaderLines])) do
              xml.files { xml.location(@data[:core][:location]) }
              taxon_id, fields = find_taxon_id(@data[:core][:fields])
              xml.id_(:term => taxon_id[0], :index => taxon_id[1])
              fields.each { |f| xml.field(:term => f[0], :index => f[1]) }
            end
            @data[:extensions].each do |e|
              xml.extension(opts.merge(:ignoreHeaderLines => e[:ignoreHeaderLines])) do
                xml.files { xml.location(e[:location]) }
                taxon_id, fields = find_taxon_id(e[:fields])
                xml.coreid(:term => taxon_id[0], :index => taxon_id[1])
                fields.each { |f| xml.field(:term => f[0], :index => f[1]) }
              end
            end
          end
        end
        meta_xml_data = builder.to_xml
        meta_file = open(File.join(@path, 'meta.xml'), @write)
        meta_file.write(meta_xml_data)
        meta_file.close
      end

      private
      def find_taxon_id(data)
        fields = []
        data.each_with_index { |f, i| fields << [f.strip, i] }
        taxon_id, fields = fields.partition { |f| f[0].match(/\/taxonid$/i) }
        raise GeneratorError if taxon_id.size != 1
        [taxon_id[0], fields]
      end

    end
  end
end

