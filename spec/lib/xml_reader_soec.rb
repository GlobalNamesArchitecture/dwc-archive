require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "DarwinCore::XmlReader" do 
  it "should parse xml to hash" do
    DarwinCore::XmlReader.public_methods.map { |i| i.to_s }.include?("from_xml").should be_true
  end

  it "should parse xml" do
    xml_string = open(File.dirname(__FILE__) + "/../files/meta.xml").read
    meta = DarwinCore::XmlReader.from_xml(xml_string)
    meta[:archive].keys.map {|k| k.to_s}.sort.should == %w(core extension)
    meta[:archive][:core].keys.map{|k| k.to_s}.sort.should == ["attributes", "field", "files", "id"]
  end

end
