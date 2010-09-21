# encoding: utf-8
require 'parsley-store'

class DarwinCore 
    
  class TaxonNormalized
    attr_accessor :id, :parent_id, :classification_path, :current_name, :current_name_canonical, :synonyms, :vernacular_names, :rank, :status

    def initialize
      @id = @parent_id = @rank = @status = nil
      @current_name = ''
      @current_name_canonical = ''
      @classification_path = []
      @synonyms = []
      @vernacular_names = []
    end

  end

  class SynonymNormalized < Struct.new(:name, :canonical_name, :status);end
  class VernacularNormalized < Struct.new(:name, :language);end

  class ClassificationNormalizer
    attr_accessor :verbose
    attr_reader :error_names, :tree

    def initialize(dwc_instance, verbose = false)
      @dwc = dwc_instance
      @core = get_fields(@dwc.core)
      @extensions = @dwc.extensions.map { |e| [e, get_fields(e)] }
      @res = {}
      @parser = ParsleyStore.new(1,2)
      @verbose = verbose
      @verbose_count = 10000
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
      @res = {}
      ingest_core
      @tree = calculate_classification_path
      ingest_extensions
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
        @parser = ParsleyStore.new(1,2)
        parsed_name = @parser.parse(a_scientific_name)[:scientificName]
      end
      add_name_string(a_scientific_name)
      add_name_string(parsed_name[:canonical]) if parsed_name[:parsed]
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
      taxon.synonyms << SynonymNormalized.new(
        row[@core[:scientificname]], 
        canonical_name(row[@core[:scientificname]]), 
        @core[:taxonomicstatus] ? row[@core[:taxonomicstatus]] : nil)
    end

    def ingest_core
      raise RuntimeError, "Darwin Core core fields must contain taxon id and scientific name" unless (@core[:id] && @core[:scientificname])
      puts "Reading core information" if @verbose
      rows = @dwc.core.read[0]
      puts "Ingesting information from the core" if @verbose
      rows.each_with_index do |r, i|
        count = i + 1
        puts "Ingesting %s'th record" % count if @verbose and count % @verbose_count == 0
        #core has AcceptedNameUsageId
        if @core[:acceptednameusageid] && r[@core[:acceptednameusageid]] && r[@core[:acceptednameusageid]] != r[@core[:id]]
          add_synonym_from_core(@core[:acceptednameusageid], r)
        elsif !@core[:acceptednameusageid] && status_synonym?(r[@core[:taxonomicstatus]])
          add_synonym_from_core(parent_id, r)
        else
          taxon = @res[r[@core[:id]]] ? @res[r[@core[:id]]] : @res[r[@core[:id]]] = DarwinCore::TaxonNormalized.new
          taxon.id = r[@core[:id]]
          taxon.current_name = r[@core[:scientificname]]
          taxon.current_name_canonical = canonical_name(r[@core[:scientificname]])
          taxon.parent_id = r[parent_id] 
          taxon.rank = r[@core[:taxonrank]] if @core[:taxonrank]
          taxon.status = r[@core[:taxonomicstatus]] if @core[:taxonomicstatus]
        end
      end
    end
    
    def parent_id
      parent_id_field = @core[:highertaxonid] || @core[:parentnameusageid]
    end

    def calculate_classification_path
      @res.each do |taxon_id, taxon|
        next if !taxon.classification_path.empty?
        begin
          node = {taxon_id => {}}
          get_classification_path(taxon, node)
        rescue DarwinCore::ParentNotCurrentError
          next
        end
      end
    end

    def get_classification_path(taxon, node)
      return if !taxon.classification_path.empty?
      if DarwinCore.nil_field?(taxon.parent_id)
        taxon.classification_path << taxon.current_name_canonical
        return @tree[taxon.id] ? @tree[taxon.id].merge!(node) : @tree[taxon.id] = node
      else
        begin
          parent_cp = @res[taxon.parent_id].classification_path
        rescue NoMethodError #name has a parent which is not a current name
          error = "The parent of the taxon \'#{taxon.current_name}\' is deprecated"
          @error_names << {:name => taxon, :error => error}
          raise DarwinCore::ParentNotCurrentError, error
        end
        if parent_cp.empty?
          node = get_classification_path(@res[taxon.parent_id], node) 
          taxon.classification_path += @res[taxon.parent_id].classification_path + [taxon.current_name_canonical]
          return node[taxon.id] = node
        else
          taxon.classification_path += parent_cp + [taxon.current_name_canonical]
          return {parent_id => node}
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
      puts "Ingesting synonyms extension" if @verbose
      ext, fields = *extension
      ext.read[0].each_with_index do |r, i|
        count = i + 1
        puts "Ingesting %s'th record" % count if @verbose && count % @verbose_count == 0
        @res[r[fields[:id]]].synonyms << SynonymNormalized.new(
          r[fields[:scientificname]], 
          canonical_name(r[fields[:scientificname]]), 
          fields[:taxonomicstatus] ? r[fields[:taxonomicstatus]] : nil)
      end
    end

    def ingest_vernaculars(extension)
      puts "Ingesting vernacular names" if @verbose
      ext, fields = *extension
      ext.read[0].each_with_index do |r, i|
        count = i + 1
        puts "Ingesting %s'th record" % count if @verbose && count % @verbose_count == 0
        @res[r[fields[:id]]].vernacular_names << VernacularNormalized.new(
          r[fields[:vernacularname]],
          fields[:languagecode] ? r[fields[:languagecode]] : nil)
        add_name_string(r[fields[:vernacularname]])
      end
    end

  end
end


