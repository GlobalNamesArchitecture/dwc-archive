# frozen_string_literal: true

class DarwinCore
  # Returns tree representation of Darwin Core file with vernacular and
  # and synonyms attached to the taxon nodes
  class ClassificationNormalizer
    attr_reader :error_names, :tree, :normalized_data, :dwc
    alias darwin_core dwc

    def initialize(dwc_instance)
      @dwc = dwc_instance
      @core_fields = find_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, find_fields(e)] }
      @normalized_data = {}
      @synonyms = {}
      @name_strings = {}
      @vernacular_name_strings = {}
      @error_names = []
      @tree = {}
    end

    def add_name_string(name_string)
      @name_strings[name_string] = 1 unless @name_strings[name_string]
    end

    def add_vernacular_name_string(name_string)
      return if @vernacular_name_strings[name_string]

      @vernacular_name_strings[name_string] = 1
    end

    def name_strings(opts = {})
      process_strings(@name_strings, opts)
    end

    def vernacular_name_strings(opts = {})
      process_strings(@vernacular_name_strings, opts)
    end

    def normalize(opts = {})
      opts = { with_canonical_names: true,
               with_extensions: true }.merge(opts)
      @with_canonical_names = opts[:with_canonical_names]
      DarwinCore.logger_write(@dwc.object_id,
                              "Started normalization of the classification")
      ingest_core
      DarwinCore.logger_write(
        @dwc.object_id,
        "Calculating the classification parent/child paths"
      )
      if parent_id?
        calculate_classification_path
      else
        @normalized_data.keys.each { |id| @tree[id] = {} }
      end
      DarwinCore.logger_write(@dwc.object_id, "Ingesting data from extensions")
      ingest_extensions if opts[:with_extensions]
      @normalized_data
    end

    private

    def process_strings(strings, opts)
      opts = { with_hash: false }.merge(opts)
      if opts[:with_hash]
        strings
      else
        strings.keys
      end
    end

    def get_canonical_name(a_scientific_name)
      return nil unless @with_canonical_names

      canonical_name = Biodiversity::Parser.parse(a_scientific_name).
                       dig(:canonical, :simple)
      canonical_name.to_s.empty? ? a_scientific_name : canonical_name
    end

    def find_fields(element)
      data = element.fields.each_with_object({}) do |f, h|
        field = f[:term].split("/")[-1]
        field = field ? field.downcase.to_sym : ""
        h[field] = f[:index].to_i
      end
      data[:id] = element.id[:index] if element.id
      data
    end

    def status_synonym?(status)
      status&.match(/^syn/)
    end

    def add_synonym_from_core(taxon_id, row)
      cf = @core_fields
      @synonyms[row[cf[:id]]] = taxon_id
      @normalized_data[row[taxon_id]] = DarwinCore::TaxonNormalized.new unless @normalized_data[row[taxon_id]]

      taxon = @normalized_data[row[taxon_id]]
      synonym = SynonymNormalized.new(
        row[cf[:id]],
        row[cf[:scientificname]],
        row[cf[:canonicalname]],
        cf[:taxonomicstatus] ? row[cf[:taxonomicstatus]] : nil,
        cf[:source] ? row[cf[:source]] : nil,
        cf[:localid] ? row[cf[:localid]] : nil,
        cf[:globalid] ? row[cf[:globalid]] : nil
      )
      taxon.synonyms << synonym
      add_name_string(synonym.name)
      add_name_string(synonym.canonical_name)
    end

    def set_scientific_name(row, fields)
      row[fields[:scientificname]] = "N/A" unless row[fields[:scientificname]]
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
      authorship = ""
      authorship = row[fields[:scientificnameauthorship]].to_s.strip if fields[:scientificnameauthorship]
      !(authorship.empty? || row[fields[:scientificname]].index(authorship))
    end

    def ingest_core
      @normalized_data = {}
      has_name_and_id = @core_fields[:id] && @core_fields[:scientificname]
      unless has_name_and_id
        raise(DarwinCore::CoreFileError,
              "Darwin Core core fields must contain taxon id and scientific name")
      end
      @dwc.core.read do |rows|
        rows[1].each do |error|
          @error_names << { data: error,
                            error: :reading_or_encoding_error }
        end
        rows[0].each do |r|
          set_scientific_name(r, @core_fields)
          # Core has AcceptedNameUsageId
          if @core_fields[:acceptednameusageid] &&
             r[@core_fields[:acceptednameusageid]] &&
             r[@core_fields[:acceptednameusageid]] != r[@core_fields[:id]]
            add_synonym_from_core(@core_fields[:acceptednameusageid], r)
          elsif !@core_fields[:acceptednameusageid] &&
                @core_fields[:taxonomicstatus] &&
                status_synonym?(r[@core_fields[:taxonomicstatus]])
            add_synonym_from_core(parent_id, r) if parent_id?
          else
            unless @normalized_data[r[@core_fields[:id]]]
              new_taxon = if gnub_archive?
                            DarwinCore::GnubTaxon.new
                          else
                            DarwinCore::TaxonNormalized.new
                          end
              @normalized_data[r[@core_fields[:id]]] = new_taxon
            end
            taxon = @normalized_data[r[@core_fields[:id]]]
            if gnub_archive?
              taxon.uuid = r[@core_fields[:originalnameusageid]]
              taxon.uuid_path = r[@core_fields[:originalnameusageidpath]].
                                split("|")
            end
            taxon.id = r[@core_fields[:id]]
            taxon.current_name = r[@core_fields[:scientificname]]
            taxon.current_name_canonical = r[@core_fields[:canonicalname]]
            taxon.parent_id = parent_id? ? r[parent_id] : nil
            taxon.rank = r[@core_fields[:taxonrank]] if @core_fields[:taxonrank]
            taxon.status = r[@core_fields[:taxonomicstatus]] if @core_fields[:taxonomicstatus]
            taxon.source = r[@core_fields[:source]] if @core_fields[:source]
            taxon.local_id = r[@core_fields[:localid]] if @core_fields[:localid]
            taxon.global_id = r[@core_fields[:globalid]] if @core_fields[:globalid]
            taxon.linnean_classification_path =
              get_linnean_classification_path(r, taxon)
            add_name_string(taxon.current_name)
            has_canonical = taxon.current_name_canonical &&
                            !taxon.current_name_canonical.empty?
            add_name_string(taxon.current_name_canonical) if has_canonical
          end
        end
      end
    end

    def parent_id?
      @has_parent_id ||= @core_fields.key?(:highertaxonid) ||
                         @core_fields.key?(:parentnameusageid)
    end

    def parent_id
      @core_fields[:highertaxonid] || @core_fields[:parentnameusageid]
    end

    def calculate_classification_path
      @paths_num = 0
      @normalized_data.each do |_taxon_id, taxon|
        next unless taxon.classification_path_id.empty?

        res = get_classification_path(taxon)
        next if res == "error"
      end
    end

    def get_classification_path(taxon)
      return unless taxon.classification_path_id.empty?

      @paths_num += 1
      if @paths_num % 10_000 == 0
        DarwinCore.logger_write(@dwc.object_id,
                                "Calculated #{@paths_num} paths")
      end
      current_node = { taxon.id => {} }
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path << taxon.current_name_canonical if @with_canonical_names
        taxon.classification_path_id << taxon.id
        @tree.merge!(current_node)
      else
        parent_cp = parent_cpid = nil
        if @normalized_data[taxon.parent_id]
          parent_cp = @normalized_data[taxon.parent_id].classification_path if @with_canonical_names
          parent_cpid = @normalized_data[taxon.parent_id].
                        classification_path_id
        else
          current_parent = @normalized_data[@synonyms[taxon.parent_id]]
          if current_parent
            @error_names << { data: taxon,
                              error: :deprecated_parent,
                              current_parent: current_parent }

            parent_cp = current_parent.classification_path if @with_canonical_names
            parent_cpid = current_parent.classification_path_id
          else
            @error_names << { data: taxon,
                              error: :deprecated_parent,
                              current_parent: nil }
          end
        end
        return "error" unless parent_cpid

        if parent_cpid.empty?
          res = "error"
          begin
            res = get_classification_path(@normalized_data[taxon.parent_id])
          rescue SystemStackError
            @error_names << { data: taxon,
                              error: :too_deep_hierarchy,
                              current_parent: nil }
          end
          return res if res == "error"

          if @with_canonical_names
            taxon.classification_path += @normalized_data[taxon.parent_id].
                                         classification_path +
                                         [taxon.current_name_canonical]
          end
          taxon.classification_path_id += @normalized_data[taxon.parent_id].
                                          classification_path_id + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].
                        classification_path_id.inject(@tree) do |node, id|
                          node[id]
                        end
          parent_node.merge!(current_node)
        else
          if @with_canonical_names
            taxon.classification_path += parent_cp +
                                         [taxon.current_name_canonical]
          end
          taxon.classification_path_id += parent_cpid + [taxon.id]
          parent_node = @normalized_data[taxon.parent_id].
                        classification_path_id.inject(@tree) do |node, id|
            node[id]
          end
          begin
            parent_node.merge!(current_node)
          rescue NoMethodError => e
            DarwinCore.logger_write(@dwc.object_id,
                                    "Error '#{e.message}' taxon #{taxon.id}")
            "error"
          end
        end
      end
    end

    def ingest_extensions
      @extensions.each do |e|
        _ext, fields = *e
        ingest_synonyms(e) if File.split(e[0].file_path).
                              last.match(/synonym/i) &&
                              fields.keys.include?(:scientificname)
        ingest_vernaculars(e) if fields.keys.include? :vernacularname
      end
    end

    def ingest_synonyms(extension)
      DarwinCore.logger_write(@dwc.object_id, "Ingesting synonyms extension")
      ext, fields = *extension
      ext.read do |rows|
        rows[0].each do |r|
          synonym = process_synonym(r, fields)
          add_synonym(synonym, r, fields)
        end
      end
    end

    def add_synonym(synonym, record, fields)
      if @normalized_data[record[fields[:id]]]
        @normalized_data[record[fields[:id]]].synonyms << synonym
        add_name_string(synonym.name)
        add_name_string(synonym.canonical_name)
      else
        @error_names << { taxon: synonym,
                          error: :synonym_of_unknown_taxa }
      end
    end

    def process_synonym(record, fields)
      set_scientific_name(record, fields)
      SynonymNormalized.new(
        nil,
        record[fields[:scientificname]],
        record[fields[:canonicalname]],
        fields[:taxonomicstatus] ? record[fields[:taxonomicstatus]] : nil,
        fields[:source] ? record[fields[:source]] : nil,
        fields[:localid] ? record[fields[:localid]] : nil,
        fields[:globalid] ? record[fields[:globalid]] : nil
      )
    end

    def ingest_vernaculars(extension)
      DarwinCore.logger_write(@dwc.object_id,
                              "Ingesting vernacular names extension")
      ext, fields = *extension
      ext.read do |rows|
        rows[0].each do |row|
          extract_vernaculars_from_row(row, fields)
        end
      end
    end

    def extract_vernaculars_from_row(row, fields)
      language = find_vernacular_language(row, fields)
      locality = fields[:locality] ? row[fields[:locality]] : nil
      country_code = fields[:countrycode] ? row[fields[:countrycode]] : nil

      vernacular = VernacularNormalized.new(
        row[fields[:vernacularname]], language, locality, country_code
      )
      if @normalized_data[row[fields[:id]]]
        @normalized_data[row[fields[:id]]].vernacular_names << vernacular
        add_vernacular_name_string(vernacular.name)
      else
        @error_names << { vernacular_name: vernacular,
                          error: :vernacular_of_unknown_taxa }
      end
    end

    def find_vernacular_language(row, fields)
      (fields[:language] && row[fields[:language]]) ||
        (fields[:languagecode] && row[fields[:languagecode]]) || nil
    end

    # Collect linnean classification path only on species level
    def get_linnean_classification_path(row, _taxon)
      %i[kingdom phylum class order family genus
         subgenus].each_with_object([]) do |clade, res|
        res << [row[@core_fields[clade]], clade] if @core_fields[clade]
      end
    end

    def gnub_archive?
      @core_fields[:originalnameusageidpath]
    end
  end
end
