class DarwinCore
  class Generator
    class EmlXml
      def initialize(data, path)
        @data = data
        @path = path
      end
      def create
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.eml( :packageId => "eml.1.1",
                 :system => "knb",
                 'xmlns:eml' => "eml://ecoinformatics.org/eml-2.1.0", 
                 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                 'xsi:schemaLocation' => "eml://ecoinformatics.org/eml-2.1.0 eml.xsd" ) do
            xml.dataset(:id => @data[:id]) do
              xml.title {@data[:title]}
              @data[:authors].each_with_index do |a, i|
                xml.creator(:id => i, :scope => 'document') do
                  xml.individualName do
                    xml.givenName {a[:first_name]}
                    xml.surName {a[:last_name]}
                  end
                  xml.electronicMailAddress {a[:email]}
                end
              end
              xml.abstract {@data[:abstract]}
            end
            xml.additionalMetadata do
              xml.metadata do
                xml.citation {@data[:citation]}
              end
            end
          end
        end
        data = builder.to_xml
        f = open(File.join(@path, 'eml.xml'), 'w:utf-8')
        f.write(data)
        f.close
      end
    end
  end
end
__END__
  <?xml version="1.0" encoding="UTF-8"?>
<eml:eml
packageId="eml.1.1" system="knb"
xmlns:eml="eml://ecoinformatics.org/eml-2.1.0"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="eml://ecoinformatics.org/eml-2.1.0 eml.xsd">
<dataset id="diatoms:version:1.0">
<title>CU*STAR Classification</title>
<creator id="1" scope="document">
<individualName>
<givenName>David</givenName>
<surName>Patterson</surName>
</individualName>
<electronicMailAddress>dpatterson@mbl.edu</electronicMailAddress>
</creator>
<creator id="2" scope="document">
<individualName>
<givenName>Community participants</givenName>
<surName></surName>
</individualName>
</creator>
<metadataProvider>
<organizationName>Encyclopedia of Life: LifeDesks (http://www.lifedesks.org)</organizationName>
</metadataProvider>
<pubDate>2010-04-14T15:55:23+00:00</pubDate>
<abstract>This is a global classification of all life with emphasis on protists.</abstract>
<intellectualRights>Creative Commons: by-nc-sa</intellectualRights>
<distribution>
<online>
</online>
</distribution>
<publisher>
<organizationName>StarCentral</organizationName>
</publisher>
</dataset>
<additionalMetadata>
<metadata>
<citation>Patterson, D. J. et al., CU*STAR. </citation>
</metadata>
</additionalMetadata>
</eml:eml>
