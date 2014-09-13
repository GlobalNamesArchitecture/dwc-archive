class DarwinCore
  # Describes normalized taxon
  class TaxonNormalized
    attr_accessor :id, :local_id, :global_id, :source, :parent_id,
                  :classification_path_id, :classification_path,
                  :linnean_classification_path, :current_name,
                  :current_name_canonical, :synonyms, :vernacular_names,
                  :rank, :status

    def initialize
      @id = @parent_id = @rank = @status = nil
      @current_name = @current_name_canonical = @source = @local_id = ""
      @global_id = ""
      @classification_path = []
      @classification_path_id = []
      @synonyms = []
      @vernacular_names = []
      @linnean_classification_path = []
    end
  end
end
