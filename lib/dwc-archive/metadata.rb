class DarwinCore
  class Metadata
    def initialize(archive = nil)
      @archive = archive
      @metadata = @archive.eml
    end

    def data
      @metadata
    end

    def id
      @metadata[:eml][:dataset][:attributes][:id] rescue nil
    end

    def title
      @metadata[:eml][:dataset][:title] rescue nil
    end

    def authors
      return nil unless defined?(@metadata[:eml][:dataset][:creator])
      @metadata[:eml][:dataset][:creator] = [@metadata[:eml][:dataset][:creator]] unless @metadata[:eml][:dataset][:creator].class == Array 
      @metadata[:eml][:dataset][:creator].map {|c| {:first_name => c[:individualName][:givenName], :last_name => c[:individualName][:surName], :email => c[:electronicMailAddress]}}
    end

    def abstract
      @metadata[:eml][:dataset][:abstract] rescue nil
    end

    def citation
      @metadata[:eml][:additionalMetadata][:metadata][:citation] rescue nil
    end

    def url
      @metadata[:eml][:dataset][:distribution][:online][:url] rescue nil
    end
  end
end
