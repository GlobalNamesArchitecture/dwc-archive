# frozen_string_literal: true

class DarwinCore
  # Represents data from EML (Ecological Metadata Language) file
  class Metadata
    attr_reader :metadata
    alias data metadata

    def initialize(archive = nil)
      @archive = archive
      @metadata = @archive.eml
    end

    def id
      fix_nil { @metadata[:eml][:dataset][:attributes][:id] }
    end

    def package_id
      fix_nil { @metadata.data[:eml][:attributes][:packageId] }
    end

    def title
      fix_nil { @metadata[:eml][:dataset][:title] }
    end

    def authors
      return nil unless defined?(@metadata[:eml][:dataset][:creator])

      authors = [@metadata[:eml][:dataset][:creator]].flatten
      authors.map do |au|
        { first_name: au[:individualName][:givenName],
          last_name: au[:individualName][:surName],
          email: au[:electronicMailAddress] }
      end
    end

    def abstract
      fix_nil { @metadata[:eml][:dataset][:abstract] }
    end

    def citation
      fix_nil { @metadata[:eml][:additionalMetadata][:metadata][:citation] }
    end

    def url
      fix_nil { @metadata[:eml][:dataset][:distribution][:online][:url] }
    end

    private

    def fix_nil
      yield
    rescue NoMethodError
      nil
    end
  end
end
