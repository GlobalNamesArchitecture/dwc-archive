# encoding: utf-8
require 'parsley-store'

class DarwinCore 
    
  class TaxonNormalized
    attr_accessor :id, :parent_id, :classification_path_id, :classification_path, :current_name, :current_name_canonical, :synonyms, :vernacular_names, :rank, :status

    def initialize
      @id = @parent_id = @rank = @status = nil
      @current_name = ''
      @current_name_canonical = ''
      @classification_path = []
      @classification_path_id = []
      @synonyms = []
      @vernacular_names = []
    end

  end

  class SynonymNormalized < Struct.new(:name, :canonical_name, :status);end
  class VernacularNormalized < Struct.new(:name, :language, :locality);end

  class ClassificationNormalizer
    attr_reader :error_names, :tree, :normalized_data

    def initialize(dwc_instance)
      @dwc = dwc_instance
      @core_fields = get_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, get_fields(e)] }
      @normalized_data = {}
      @synonyms = {}
      @parser = ParsleyStore.new(1,2)
      @name_strings = {}
      @error_names = []
      @tree = {}
    end

    def add_name_string(name_string)
      @name_strings[name_string] = 1 unless @name_strings[name_string]
    end

    def name_strings
      @name_strings.keys
    end

    def normalize
      DarwinCore.logger_write(@dwc.object_id, "Started normalization of the classification")
      @normalized_data = {}
      ingest_core
      DarwinCore.logger_write(@dwc.object_id, "Calculating the classification parent/child paths")
      calculate_classification_path
      DarwinCore.logger_write(@dwc.object_id, "Ingesting data from extensions")
      ingest_extensions
      @normalized_data
    end

  private

    def get_canonical_name(a_scientific_name)
      if R19
        a_scientific_name.force_encoding('utf-8')
      end
      canonical_name = @parser.parse(a_scientific_name, :canonical_only => true)
      canonical_name.to_s.empty? ? a_scientific_name : canonical_name
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
      @synonyms[row[@core_fields[:id]]] = taxon_id
      taxon = @normalized_data[row[taxon_id]] ? @normalized_data[row[taxon_id]] : @normalized_data[row[taxon_id]] = DarwinCore::TaxonNormalized.new
      synonym = SynonymNormalized.new(
        row[@core_fields[:scientificname]], 
        row[@core_fields[:canonicalname]], 
        @core_fields[:taxonomicstatus] ? row[@core_fields[:taxonomicstatus]] : nil)
      taxon.synonyms <<  synonym
      add_name_string(synonym.name)
      add_name_string(synonym.canonical_name)
    end

    def set_scientific_name(row, fields)
      row[fields[:scientificname]] = 'N/A' unless row[fields[:scientificname]]
      canonical_name = fields[:scientificnameauthorship] ? row[fields[:scientificname]] : get_canonical_name(row[fields[:scientificname]])
      fields[:canonicalname] = row.size
      row << canonical_name
      scientific_name = (fields[:scientificnameauthorship] && row[fields[:scientificnameauthorship]].to_s.strip != '') ? row[fields[:scientificname]].strip + ' ' + row[fields[:scientificnameauthorship]].strip : row[fields[:scientificname]].strip
      row[fields[:scientificname]] = scientific_name
    end

    def ingest_core
      raise RuntimeError, "Darwin Core core fields must contain taxon id and scientific name" unless (@core_fields[:id] && @core_fields[:scientificname])
      @dwc.core.read do |rows|
        rows[0].each do |r|
          set_scientific_name(r, @core_fields)
          #core has AcceptedNameUsageId
          if @core_fields[:acceptednameusageid] && r[@core_fields[:acceptednameusageid]] && r[@core_fields[:acceptednameusageid]] != r[@core_fields[:id]]
            add_synonym_from_core(@core_fields[:acceptednameusageid], r)
          elsif !@core_fields[:acceptednameusageid] && @core_fields[:taxonomicstatus] && status_synonym?(r[@core_fields[:taxonomicstatus]])
            add_synonym_from_core(parent_id, r)
          else
            taxon = @normalized_data[r[@core_fields[:id]]] ? @normalized_data[r[@core_fields[:id]]] : @normalized_data[r[@core_fields[:id]]] = DarwinCore::TaxonNormalized.new
            taxon.id = r[@core_fields[:id]]
            taxon.current_name = r[@core_fields[:scientificname]]
            taxon.current_name_canonical = r[@core_fields[:canonicalname]]
            taxon.parent_id = r[parent_id] 
            taxon.rank = r[@core_fields[:taxonrank]] if @core_fields[:taxonrank]
            taxon.status = r[@core_fields[:taxonomicstatus]] if @core_fields[:taxonomicstatus]
            add_name_string(taxon.current_name)
            add_name_string(taxon.current_name_canonical)
          end
        end
      end
    end
    
    def parent_id
      parent_id_field = @core_fields[:highertaxonid] || @core_fields[:parentnameusageid]
    end

    def calculate_classification_path
      @paths_num = 0
      @normalized_data.each do |taxon_id, taxon|
        next if !taxon.classification_path.empty?
        res = get_classification_path(taxon)
        next if res == 'error'
      end
    end

    def get_classification_path(taxon)
      return if !taxon.classification_path.empty?
      @paths_num += 1
      DarwinCore.logger_write(@dwc.object_id, "Calculated %s paths" % @paths_num) if @paths_num % 10000 == 0
      current_node = {taxon.id => {}}
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path << taxon.current_name_canonical
        taxon.classification_path_id << taxon.id
        @tree.merge!(current_node)
      else
        parent_cp = nil
        if @normalized_data[taxon.parent_id]
          parent_cp = @normalized_data[taxon.parent_id].classification_path
        else
          current_parent = @normalized_data[@synonyms[taxon.parent_id]]
          if current_parent
            error = "WARNING: The parent of the taxon \'#{taxon.current_name}\' is deprecated"
            @error_names << {:name => taxon, :error => :deprecated_parent, :current_parent => current_parent }
            parent_cp = current_parent.classification_path
          else
            error = "WARNING: The parent of the taxon \'#{taxon.current_name}\' not found"
            @error_names << {:name => taxon, :error => :deprecated_parent, :current_parent => nil}
          end  
        end
        return 'error' unless parent_cp
        if parent_cp.empty?
          res = get_classification_path(@normalized_data[taxon.parent_id]) 
          return res if res == 'error'
          taxon.classification_path += @normalized_data[taxon.parent_id].classification_path + [taxon.current_name_canonical]
          taxon.classification_path_id += @normalized_data[taxon.parent_id].classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].classification_path_id.inject(@tree) {|node, id| node[id]}
          parent_node.merge!(current_node)
        else
          taxon.classification_path += parent_cp + [taxon.current_name_canonical]
          taxon.classification_path_id += @normalized_data[taxon.parent_id].classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].classification_path_id.inject(@tree) {|node, id| node[id]}
          begin
            parent_node.merge!(current_node)
          rescue NoMethodError => e
            DarwinCore.logger_write(@dwc.object_id, "Error '%s' taxon %s" % [e.message, taxon.id])
            return 'error'
          end
        end
      end
    end

    def ingest_extensions
      @extensions.each do |e|
        ext, fields = *e
        ingest_synonyms(e) if fields.keys.include? :scientificname
        ingest_vernaculars(e) if fields.keys.include? :vernacularname
      end
    end
    
    def ingest_synonyms(extension)
      DarwinCore.logger_write(@dwc.object_id, "Ingesting synonyms extension")
      ext, fields = *extension
      ext.read do |rows|
        rows[0].each do |r|
          set_scientific_name(r, fields)
          synonym = SynonymNormalized.new(
            r[fields[:scientificname]], 
            r[fields[:canonicalname]], 
            fields[:taxonomicstatus] ? r[fields[:taxonomicstatus]] : nil)
          @normalized_data[r[fields[:id]]].synonyms << synonym
          add_name_string(synonym.name)
          add_name_string(synonym.canonical_name)
        end
      end
    end

    def ingest_vernaculars(extension)
      DarwinCore.logger_write(@dwc.object_id, "Ingesting vernacular names extension")
      ext, fields = *extension
      ext.read do |rows|
        rows[0].each do |r|

          language = nil
          if fields[:language]
            language = r[fields[:language]]
          elsif fields[:languagecode]
            language = r[fields[:languagecode]] 
          end
          
          locality = fields[:locality] ? r[fields[:locality]] : nil
          
          vernacular = VernacularNormalized.new(
            r[fields[:vernacularname]],
            language,
            locality)
          @normalized_data[r[fields[:id]]].vernacular_names << vernacular
          add_name_string(vernacular.name)
        end
      end
    end

  end
end


