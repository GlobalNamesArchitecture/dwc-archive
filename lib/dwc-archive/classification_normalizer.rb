require 'biodiversity'

class DarwinCore 
  

  class ClassificationNormalizer
    def initialize(dwc_instance)
      @dwc = dwc_instance
      @core = get_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, get_fields(e)] }
      @taxon_template = {
        :parent_id => nil,
        :classification_path => nil,
        :current_name => nil,
        :current_name_canonical => nil,
        :synonyms => [],
        :vernacular_names => [],
        :status => nil,
      }
      @res = {}
      @parser = ScientificNameParser.new
    end

    def normalize
      injest_core
      calculate_classification_path
      injest_extensions
      require 'ruby-debug'; debugger
      puts ''
    end


    private

    def canonical_name(a_scientific_name)
      begin
        parsed_name = @parser.parse(a_scientific_name)[:scientificName]
      rescue
        @parser = ScientificNameParser.new
        parsed_name = @parser.parse(a_scientific_name)[:scientificName]
      end
      parsed_name[:parsed] ? parsed_name[:canonical] : a_scientific_name
    end
    
    def get_fields(element)
      data = element.fields.inject({}) { |res, f| res[f[:term].split('/')[-1].downcase.to_sym] = f[:index].to_i; res }
      data[:id] = element.id[:index] 
      data
    end
    
    def injest_core
      raise RuntimeError, "Darwin Core core fields must contain id and scientific_name" unless (@core[:id] && @core[:scientificname])
      taxon_id_index = @core[:id] 
      scientific_name_index = @core[:scientificname]
      higher_taxa_id_index = @core[:highertaxaid]
      accepted_name_usage_id_index = @core[:acceptednameusageid]
      taxon_rank_index = @core[:taxonrank]
      taxonomic_status_index = @core[:taxonomicstatus]
      @dwc.core.read[0].each do |r|
        if accepted_name_usage_id_index && r[accepted_name_usage_id_index] && r[accepted_name_usage_id_index] != r[taxon_id_index]
          taxon = @res[r[@core[:acceptednameusageid]]] ? @res[r[@core[:acceptednameusageid]]] : @res[r[@core[:acceptednameusageid]]] = @taxon_template.clone
          taxon[:synonyms] << {
            :name => r[@core[:scientificname]], 
            :canonical_name => canonical_name(r[@core[:scientificname]]), 
            :status => r[@core[:taxonomicstatus]]}
        else
          taxon = @res[r[@core[:id]]] ? @res[r[@core[:id]]] : @res[r[@core[:id]]] = @taxon_template.clone
          taxon[:current_name] = r[@core[:scientificname]]
          taxon[:current_name_canonical] = canonical_name(taxon[:current_name])
          taxon[:parent_id] = r[@core[:highertaxonid]]
          taxon[:rank] = r[@core[:taxonrank]]
          taxon[:status] = r[@core[:taxonomicstatus]]
        end
      end
    end

    def calculate_classification_path
      @res.each do |taxon_id, taxon|
        next if taxon[:classification_path]
        get_classification_path(taxon)
      end
    end

    def get_classification_path(taxon)
      return if taxon[:classification_path]
      if DarwinCore.nil_field?(taxon[:parent_id])
        taxon[:classification_path] = [taxon[:current_name_canonical]]
      else
         parent_cp = @res[taxon[:parent_id]][:classification_path]
        if parent_cp
          taxon[:classification_path] = parent_cp + [taxon[:current_name_canonical]]
        else
          get_classification_path(@res[taxon[:parent_id]]) 
          taxon[:classification_path] = @res[taxon[:parent_id]][:classification_path] + [taxon[:current_name_canonical]]
        end
      end
    end

    def injest_extensions
      @extensions.each do |e|
        ext, fields = *e
      require 'ruby-debug'; debugger
        injest_synonyms(e) if fields.keys.include? :scientificname
        injest_vernaculars(e) if fields.keys.include? :vernacularname
      end
    end
    
    def injest_synonyms(extension)
      ext, fields = *extension
      ext.read[0].each do |r|
        @res[r[fields[:id]]][:synonyms] << {
          :name => r[fields[:scientificname]], 
          :canonical_name => canonical_name(r[fields[:scientificname]]), 
          :status => r[fields[:taxonomicstatus]]}
      end
    end

    def injest_vernaculars(extension)
      ext, fields = *extension
      ext.read[0].each do |r|
        @res[r[fields[:id]]][:vernacular_names] << {
          :name => r[fields[:vernacularname]],
          :language => r[fields[:languagecode]]
        }
      end
    end

  end
end
