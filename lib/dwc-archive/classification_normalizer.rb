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
  class VernacularNormalized < Struct.new(:name, :language);end

  class ClassificationNormalizer
    attr_reader :error_names, :tree, :normalized_data

    def initialize(dwc_instance)
      @dwc = dwc_instance
      @core_fields = get_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, get_fields(e)] }
      @normalized_data = {}
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
      add_name_string(a_scientific_name)
      add_name_string(canonical_name) unless canonical_name.to_s.empty?
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
      taxon = @normalized_data[row[taxon_id]] ? @normalized_data[row[taxon_id]] : @normalized_data[row[taxon_id]] = DarwinCore::TaxonNormalized.new
      taxon.synonyms << SynonymNormalized.new(
        row[@core_fields[:scientificname]], 
        row[@core_fields[:canonicalname]], 
        @core_fields[:taxonomicstatus] ? row[@core_fields[:taxonomicstatus]] : nil)
    end

    def set_scientific_name(row, fields)
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
          elsif !@core_fields[:acceptednameusageid] && status_synonym?(r[@core_fields[:taxonomicstatus]])
            add_synonym_from_core(parent_id, r)
          else
            taxon = @normalized_data[r[@core_fields[:id]]] ? @normalized_data[r[@core_fields[:id]]] : @normalized_data[r[@core_fields[:id]]] = DarwinCore::TaxonNormalized.new
            taxon.id = r[@core_fields[:id]]
            taxon.current_name = r[@core_fields[:scientificname]]
            taxon.current_name_canonical = r[@core_fields[:canonicalname]]
            taxon.parent_id = r[parent_id] 
            taxon.rank = r[@core_fields[:taxonrank]] if @core_fields[:taxonrank]
            taxon.status = r[@core_fields[:taxonomicstatus]] if @core_fields[:taxonomicstatus]
          end
        end
      end
    end
    
    def parent_id
      parent_id_field = @core_fields[:highertaxonid] || @core_fields[:parentnameusageid]
    end

    def calculate_classification_path
      @normalized_data.each do |taxon_id, taxon|
        next if !taxon.classification_path.empty?
        begin
          get_classification_path(taxon)
        rescue DarwinCore::ParentNotCurrentError
          next
        end
      end
    end

    def get_classification_path(taxon)
      return if !taxon.classification_path.empty?
      current_node = {taxon.id => {}}
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path << taxon.current_name_canonical
        taxon.classification_path_id << taxon.id
        @tree.merge!(current_node)
      else
        begin
          parent_cp = @normalized_data[taxon.parent_id].classification_path
        rescue NoMethodError #name has a parent which is not a current name
          error = "The parent of the taxon \'#{taxon.current_name}\' is deprecated"
          @error_names << {:name => taxon, :error => error}
          raise DarwinCore::ParentNotCurrentError, error
        end
        if parent_cp.empty?
          get_classification_path(@normalized_data[taxon.parent_id]) 
          taxon.classification_path += @normalized_data[taxon.parent_id].classification_path + [taxon.current_name_canonical]
          taxon.classification_path_id += @normalized_data[taxon.parent_id].classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].classification_path_id.inject(@tree) {|node, id| node[id]}
          parent_node.merge!(current_node)
        else
          taxon.classification_path += parent_cp + [taxon.current_name_canonical]
          taxon.classification_path_id += @normalized_data[taxon.parent_id].classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].classification_path_id.inject(@tree) {|node, id| node[id]}
          parent_node.merge!(current_node)
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
          @normalized_data[r[fields[:id]]].synonyms << SynonymNormalized.new(
            r[fields[:scientificname]], 
            r[fields[:canonicalname]], 
            fields[:taxonomicstatus] ? r[fields[:taxonomicstatus]] : nil)
        end
      end
    end

    def ingest_vernaculars(extension)
      DarwinCore.logger_write(@dwc.object_id, "Ingesting vernacular names extension")
      ext, fields = *extension
      ext.read do |rows|
        rows[0].each do |r|
          @normalized_data[r[fields[:id]]].vernacular_names << VernacularNormalized.new(
            r[fields[:vernacularname]],
            fields[:languagecode] ? r[fields[:languagecode]] : nil)
          add_name_string(r[fields[:vernacularname]])
        end
      end
    end

  end
end
