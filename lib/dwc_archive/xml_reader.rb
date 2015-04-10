class DarwinCore
  # USAGE: Hash.from_xml:(YOUR_XML_STRING)
  # modified from
  # http://stackoverflow.com/questions/1230741/
  # convert-a-nokogiri-document-to-a-ruby-hash/1231297#1231297
  module XmlReader
    class << self
      def from_xml(xml_io)
        result = Nokogiri::XML(xml_io)
        { result.root.name.to_sym => xml_node_to_hash(result.root) }
      end

      private

      def xml_node_to_hash(node)
        # If we are at the root of the document, start the hash
        if node.element?
          prepare_node_element(node)
        else
          return prepare(node.content.to_s)
        end
      end

      def add_attributes(node, result_hash)
        return if node.attributes.empty?
        result_hash[:attributes] = {}
        node.attributes.keys.each do |key|
          add_attribute(result_hash[:attributes], node.attributes[key])
        end
      end

      def add_attribute(attributes, attribute)
        attributes[attribute.name.to_sym] = prepare(attribute.value)
      end

      def prepare_node_element(node)
        result_hash = {}
        add_attributes(node, result_hash)
        result_hash = add_children(node, result_hash) if node.children.size > 0
        result_hash
      end

      def add_children(node, result_hash)
        node.children.each do |child|
          text = process_child(child, result_hash)
          return text if text
        end
        result_hash
      end

      def process_child(node, result_hash)
        result = xml_node_to_hash(node)
        text = nil
        if node.name == "text"
          text = handle_text(node, result)
        elsif result_hash[node.name.to_sym]
          handle_child_node(node, result_hash, result)
        else
          result_hash[node.name.to_sym] = prepare(result)
        end
        text
      end

      def handle_child_node(child, result_hash, result)
        if result_hash[child.name.to_sym].is_a?(Object::Array)
          result_hash[child.name.to_sym] << prepare(result)
        else
          result_hash[child.name.to_sym] =
            [result_hash[child.name.to_sym]] << prepare(result)
        end
      end

      def handle_text(child, result)
        prepare(result) unless child.next_sibling || child.previous_sibling
      end

      def prepare(data)
        (data.class == String && data.to_i.to_s == data) ? data.to_i : data
      end
    end
  end
end
