# encoding: utf-8
require 'biodiversity'

class DarwinCore 
  
  class TaxonNormalized
    attr_accessor :id, :parent_id, :classification_path, :current_name, :current_name_canonical, :synonyms, :vernacular_names, :rank, :status

    def initialize
      @id = @parent_id = @classification_path = @current_name = @current_name_canonical = @rank = @status = nil
      @synonyms = []
      @vernacular_names = []
    end

  end

  class ClassificationNormalizer
    def initialize(dwc_instance)
      @dwc = dwc_instance
      @core = get_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, get_fields(e)] }
      @res = {}
      @parser = ScientificNameParser.new
    end

    def normalize
      injest_core
      calculate_classification_path
      injest_extensions
      @res
    end

  private

    def canonical_name(a_scientific_name)
      if R19
        a_scientific_name.force_encoding('utf-8')
      end
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

    def status_synonym?(status)
      status && !!status.match(/^syn/)
    end
    
    def add_synonym_from_core(taxon_id, row)
      taxon = @res[row[taxon_id]] ? @res[row[taxon_id]] : @res[row[taxon_id]] = DarwinCore::TaxonNormalized.new
      taxon.synonyms << {
        :name => row[@core[:scientificname]], 
        :canonical_name => canonical_name(row[@core[:scientificname]]), 
        :status => row[@core[:taxonomicstatus]]}
    end

    def injest_core
      raise RuntimeError, "Darwin Core core fields must contain taxon id and scientific name" unless (@core[:id] && @core[:scientificname])
      @dwc.core.read[0].each do |r|
        #core has AcceptedNameUsageId
        if @core[:acceptednameusageid] && r[@core[:acceptednameusageid]] && r[@core[:acceptednameusageid]] != r[@core[:id]]
          add_synonym_from_core(@core[:acceptednameusageid], r)
        elsif !@core[:acceptednameusageid] && status_synonym?(r[@core[:taxonomicstatus]])
          add_synonym_from_core(@core[:highertaxonid], r)
        else
          taxon = @res[r[@core[:id]]] ? @res[r[@core[:id]]] : @res[r[@core[:id]]] = DarwinCore::TaxonNormalized.new
          taxon.id = r[@core[:id]]
          taxon.current_name = r[@core[:scientificname]]
          taxon.current_name_canonical = canonical_name(r[@core[:scientificname]])
          taxon.parent_id = r[@core[:highertaxonid]]
          taxon.rank = r[@core[:taxonrank]]
          taxon.status = r[@core[:taxonomicstatus]]
        end
      end
    end

    def calculate_classification_path
      @res.each do |taxon_id, taxon|
        next if taxon.classification_path
        get_classification_path(taxon)
      end
    end

    def get_classification_path(taxon)
      return if taxon.classification_path
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path = [taxon.current_name_canonical]
      else
         parent_cp = @res[taxon.parent_id].classification_path
        if parent_cp
          taxon.classification_path = parent_cp + [taxon.current_name_canonical]
        else
          get_classification_path(@res[taxon.parent_id]) 
          taxon.classification_path = @res[taxon.parent_id].classification_path + [taxon.current_name_canonical]
        end
      end
    end

    def injest_extensions
      @extensions.each do |e|
        ext, fields = *e
        injest_synonyms(e) if fields.keys.include? :scientificname
        injest_vernaculars(e) if fields.keys.include? :vernacularname
      end
    end
    
    def injest_synonyms(extension)
      ext, fields = *extension
      ext.read[0].each do |r|
        @res[r[fields[:id]]].synonyms << {
          :name => r[fields[:scientificname]], 
          :canonical_name => canonical_name(r[fields[:scientificname]]), 
          :status => r[fields[:taxonomicstatus]]}
      end
    end

    def injest_vernaculars(extension)
      ext, fields = *extension
      ext.read[0].each do |r|
        @res[r[fields[:id]]].vernacular_names << {
          :name => r[fields[:vernacularname]],
          :language => r[fields[:languagecode]]
        }
      end
    end

  end
end
