# encoding: utf-8
require 'parsley-store'

class DarwinCore

  class TaxonNormalized
    attr_accessor :id, :local_id, :global_id, :source, :parent_id, :classification_path_id, :classification_path, :linnean_classification_path, :current_name, :current_name_canonical, :synonyms, :vernacular_names, :rank, :status

    def initialize
      @id = @parent_id = @rank = @status = nil
      @current_name = ''
      @current_name_canonical = ''
      @source = ''
      @local_id = ''
      @global_id = ''
      @classification_path = []
      @classification_path_id = []
      @synonyms = []
      @vernacular_names = []
      @linnean_classification_path = []
    end

  end

  class SynonymNormalized < Struct.new(:id, :name, :canonical_name, :status, :source, :local_id, :global_id);end
  class VernacularNormalized < Struct.new(:name, :language, :locality, :country_code);end

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
      @vernacular_name_strings = {}
      @error_names = []
      @tree = {}
    end

    def add_name_string(name_string)
      @name_strings[name_string] = 1 unless @name_strings[name_string]
    end

    def add_vernacular_name_string(name_string)
      @vernacular_name_strings[name_string] = 1 unless @vernacular_name_strings[name_string]
    end

    def name_strings(opts = {})
      opts = { with_hash: false }.merge(opts)
      if !!opts[:with_hash]
        @name_strings
      else
        @name_strings.keys
      end
    end

    def vernacular_name_strings(opts = {})
      opts = { with_hash: false }.merge(opts)
      if !!opts[:with_hash]
        @vernacular_name_strings
      else
        @vernacular_name_strings.keys
      end
    end

    def normalize(opts = {})
      opts = { :with_canonical_names => true, :with_extensions => true }.merge(opts)
      @with_canonical_names = !!opts[:with_canonical_names]
      DarwinCore.logger_write(@dwc.object_id, "Started normalization of the classification")
      ingest_core
      DarwinCore.logger_write(@dwc.object_id, "Calculating the classification parent/child paths")
      has_parent_id? ? calculate_classification_path : @normalized_data.keys.each { |id| @tree[id] = {} }
      DarwinCore.logger_write(@dwc.object_id, "Ingesting data from extensions")
      if !!opts[:with_extensions]
        ingest_extensions
      end
      @normalized_data
    end

  private

    def get_canonical_name(a_scientific_name)
      if @with_canonical_names
        canonical_name = @parser.parse(a_scientific_name, :canonical_only => true)
        canonical_name.to_s.empty? ? a_scientific_name : canonical_name
      else
        nil
      end
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
        row[@core_fields[:id]],
        row[@core_fields[:scientificname]],
        row[@core_fields[:canonicalname]],
        @core_fields[:taxonomicstatus] ? row[@core_fields[:taxonomicstatus]] : nil,
        @core_fields[:source] ? row[@core_fields[:source]] : nil,
        @core_fields[:localid] ? row[@core_fields[:localid]] : nil,
        @core_fields[:globalid] ? row[@core_fields[:globalid]] : nil,
      )
      taxon.synonyms <<  synonym
      add_name_string(synonym.name)
      add_name_string(synonym.canonical_name)
    end

    def set_scientific_name(row, fields)
      row[fields[:scientificname]] = 'N/A' unless row[fields[:scientificname]]
      canonical_name = nil
      scientific_name = row[fields[:scientificname]].strip
      if separate_canonical_and_authorship?(row, fields)
        canonical_name = row[fields[:scientificname]].strip if @with_canonical_names
        scientific_name += " #{row[fields[:scientificnameauthorship]].strip}"
      else
        canonical_name = get_canonical_name(row[fields[:scientificname]]) if @with_canonical_names
      end
      fields[:canonicalname] = row.size
      row << canonical_name
      row[fields[:scientificname]] = scientific_name
    end

    def separate_canonical_and_authorship?(row, fields)
      authorship = ''
      if fields[:scientificnameauthorship]
        authorship = row[fields[:scientificnameauthorship]].to_s.strip
      end
      !(authorship.empty? || row[fields[:scientificname]].index(authorship))
    end

    def ingest_core
      @normalized_data = {}
      raise DarwinCore::CoreFileError.new("Darwin Core core fields must contain taxon id and scientific name") unless (@core_fields[:id] && @core_fields[:scientificname])
      @dwc.core.read do |rows|
        rows[1].each do |error|
          @error_names << { :data => error, :error => :reading_or_encoding_error }
        end
        rows[0].each do |r|
          set_scientific_name(r, @core_fields)
          #core has AcceptedNameUsageId
          if @core_fields[:acceptednameusageid] && r[@core_fields[:acceptednameusageid]] && r[@core_fields[:acceptednameusageid]] != r[@core_fields[:id]]
            add_synonym_from_core(@core_fields[:acceptednameusageid], r)
          elsif !@core_fields[:acceptednameusageid] && @core_fields[:taxonomicstatus] && status_synonym?(r[@core_fields[:taxonomicstatus]])
            add_synonym_from_core(parent_id, r) if has_parent_id?
          else
            taxon = @normalized_data[r[@core_fields[:id]]] ? @normalized_data[r[@core_fields[:id]]] : @normalized_data[r[@core_fields[:id]]] = DarwinCore::TaxonNormalized.new
            taxon.id = r[@core_fields[:id]]
            taxon.current_name = r[@core_fields[:scientificname]]
            taxon.current_name_canonical = r[@core_fields[:canonicalname]]
            taxon.parent_id = has_parent_id? ? r[parent_id] : nil
            taxon.rank = r[@core_fields[:taxonrank]] if @core_fields[:taxonrank]
            taxon.status = r[@core_fields[:taxonomicstatus]] if @core_fields[:taxonomicstatus]
            taxon.source = r[@core_fields[:source]] if @core_fields[:source]
            taxon.local_id = r[@core_fields[:localid]] if @core_fields[:localid]
            taxon.global_id = r[@core_fields[:globalid]] if @core_fields[:globalid]
            taxon.linnean_classification_path = get_linnean_classification_path(r, taxon)
            add_name_string(taxon.current_name)
            add_name_string(taxon.current_name_canonical) if taxon.current_name_canonical && !taxon.current_name_canonical.empty?
          end
        end
      end
    end

    def has_parent_id?
      @has_parent_id ||= @core_fields.has_key?(:highertaxonid) || @core_fields.has_key?(:parentnameusageid)
    end

    def parent_id
      parent_id_field = @core_fields[:highertaxonid] || @core_fields[:parentnameusageid]
    end

    def calculate_classification_path
      @paths_num = 0
      @normalized_data.each do |taxon_id, taxon|
        next if !taxon.classification_path_id.empty?
        res = get_classification_path(taxon)
        next if res == 'error'
      end
    end

    def get_classification_path(taxon)
      return if !taxon.classification_path_id.empty?
      @paths_num += 1
      DarwinCore.logger_write(@dwc.object_id, "Calculated %s paths" % @paths_num) if @paths_num % 10000 == 0
      current_node = {taxon.id => {}}
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path << taxon.current_name_canonical if @with_canonical_names
        taxon.classification_path_id << taxon.id
        @tree.merge!(current_node)
      else
        parent_cp = parent_cpid = nil
        if @normalized_data[taxon.parent_id]
          parent_cp = @normalized_data[taxon.parent_id].classification_path if @with_canonical_names
          parent_cpid = @normalized_data[taxon.parent_id].classification_path_id
        else
          current_parent = @normalized_data[@synonyms[taxon.parent_id]]
          if current_parent
            error = "WARNING: The parent of the taxon \'#{taxon.current_name}\' is deprecated"
            @error_names << {:data => taxon, :error => :deprecated_parent, :current_parent => current_parent }

            parent_cp = current_parent.classification_path if @with_canonical_names
            parent_cpid = current_parent.classification_path_id
          else
            error = "WARNING: The parent of the taxon \'#{taxon.current_name}\' not found"
            @error_names << {:data => taxon, :error => :deprecated_parent, :current_parent => nil}
          end
        end
        return 'error' unless parent_cpid
        if parent_cpid.empty?
          res = 'error'
          begin
            res = get_classification_path(@normalized_data[taxon.parent_id])
          rescue SystemStackError
            @error_names << {:data => taxon, :error => :too_deep_hierarchy, :current_parent => nil}
          end
          return res if res == 'error'
          if @with_canonical_names
            taxon.classification_path += @normalized_data[taxon.parent_id].classification_path + [taxon.current_name_canonical]
          end
          taxon.classification_path_id += @normalized_data[taxon.parent_id].classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].classification_path_id.inject(@tree) {|node, id| node[id]}
          parent_node.merge!(current_node)
        else
          taxon.classification_path += parent_cp + [taxon.current_name_canonical] if @with_canonical_names
          taxon.classification_path_id += parent_cpid + [taxon.id]
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
        ingest_synonyms(e) if (File.split(e[0].file_path).last.match(/synonym/i) && fields.keys.include?(:scientificname))
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
            nil,
            r[fields[:scientificname]],
            r[fields[:canonicalname]],
            fields[:taxonomicstatus] ? r[fields[:taxonomicstatus]] : nil,
            fields[:source] ? r[fields[:source]] : nil,
            fields[:localid] ? r[fields[:localid]] : nil,
            fields[:globalid] ? r[fields[:globalid]] : nil,
          )
          if @normalized_data[r[fields[:id]]]
            @normalized_data[r[fields[:id]]].synonyms << synonym
            add_name_string(synonym.name)
            add_name_string(synonym.canonical_name)
          else
            @error_names << { :taxon => synonym, :error => :synonym_of_unknown_taxa }
          end
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

          country_code = fields[:countrycode] ? r[fields[:countrycode]] : nil

          vernacular = VernacularNormalized.new(
            r[fields[:vernacularname]],
            language,
            locality,
            country_code)
          if @normalized_data[r[fields[:id]]]
            @normalized_data[r[fields[:id]]].vernacular_names << vernacular
            add_vernacular_name_string(vernacular.name)
          else
            @error_names << { :vernacular_name => vernacular, :error => :vernacular_of_unknown_taxa }
          end
        end
      end
    end
    
    #Collect linnean classification path only on species level
    def get_linnean_classification_path(row, taxon)
      res = []
      [:kingdom, :phylum, :class, :order, :family, :genus, :subgenus].each do |clade|
        res << [row[@core_fields[clade]], clade] if @core_fields[clade] 
      end
      res
    end

  end
end
