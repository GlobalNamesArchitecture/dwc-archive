# frozen_string_literal: true

class DarwinCore
  # Covers special case of Global Names Usage Bank data
  class GnubTaxon < TaxonNormalized
    attr_accessor :uuid, :uuid_path

    def initialize
      super
      @uuid = nil
      @uuid_path = []
    end
  end
end
