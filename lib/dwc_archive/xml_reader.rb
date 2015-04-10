class DarwinCore
  # USAGE: Hash.from_xml:(YOUR_XML_STRING)
  # modified from
  # http://stackoverflow.com/questions/1230741/
  # convert-a-nokogiri-document-to-a-ruby-hash/1231297#1231297
  module XmlReader
    def self.from_xml(xml_io)
      result = Nokogiri::XML(xml_io)
      { result.root.name.to_sym => self::Node.new(result.root).value }
    end

    # Node is a helper class to parse xml into hash
    class Node
      def initialize(node)
        @node = node
        @val = {}
      end

      def value
        if @node.element?
          prepare_node_element
        else
          prepare(@node.content.to_s)
        end
      end

      private

      def prepare_node_element
        add_attributes
        add_children if @node.children.size > 0
        @val
      end

      def prepare(data)
        (data.class == String && data.to_i.to_s == data) ? data.to_i : data
      end

      def add_attributes
        return if @node.attributes.empty?
        @val[:attributes] = {}
        @node.attributes.keys.each do |key|
          add_attribute(@val[:attributes], @node.attributes[key])
        end
      end

      def add_attribute(attributes, attribute)
        attributes[attribute.name.to_sym] = prepare(attribute.value)
      end

      def add_children
        @node.children.each do |child|
          process_child(child)
        end
      end

      def process_child(child)
        value = DarwinCore::XmlReader::Node.new(child).value
        if child.name == "text"
          handle_text(child, value)
        else
          add_child_to_value(child, value)
        end
      end

      def add_child_to_value(child, value)
        if @val[child.name.to_sym]
          handle_child_node(child.name.to_sym, value)
        else
          @val[child.name.to_sym] = prepare(value)
        end
      end

      def handle_child_node(child, val)
        if @val[child].is_a?(Object::Array)
          @val[child] << prepare(val)
        else
          @val[child] = [@val[child], prepare(val)]
        end
      end

      def handle_text(child, val)
        @val = prepare(val) unless child.next_sibling || child.previous_sibling
      end
    end
  end
end
