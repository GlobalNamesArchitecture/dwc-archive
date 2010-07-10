class DarwinCore
  class Generator
    class EmlXml
      def initialize(data, path)
        @data = data
        @path = path
        @write = R19 ? 'w:utf-8' : 'w'
      end
      def create
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.eml( :packageId => "eml.1.1",
                 :system => "knb",
                 'xmlns:eml' => "eml://ecoinformatics.org/eml-2.1.0", 
                 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                 'xsi:schemaLocation' => "eml://ecoinformatics.org/eml-2.1.0 eml.xsd" ) do
            xml.dataset(:id => @data[:id]) do
              xml.title(@data[:title])
              contacts = []
              @data[:authors].each_with_index do |a, i|
                creator_id = i + 1
                contacts << creator_id
                xml.creator(:id => creator_id, :scope => 'document') do
                  xml.individualName do
                    xml.givenName(a[:first_name])
                    xml.surName(a[:last_name])
                  end
                  xml.electronicMailAddress(a[:email])
                end
              end
              xml.abstract(@data[:abstract])
              contacts.each do |contact|
                xml.contact { xml.references(contact) }
              end
            end
            xml.additionalMetadata do
              xml.metadata do
                xml.citation(@data[:citation])
              end
            end
            xml.parent.namespace = xml.parent.namespace_definitions.first
          end
        end
        data = builder.to_xml
        f = open(File.join(@path, 'eml.xml'), @write)
        f.write(data)
        f.close
      end
    end
  end
end
