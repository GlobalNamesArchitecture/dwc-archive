# frozen_string_literal: true

class DarwinCore
  # Represents core of the DarwinCore Archive
  class Core
    include DarwinCore::Ingester
    attr_reader :id

    # rubocop:disable Metrics/MethodLength
    def initialize(dwc)
      @dwc = dwc
      @archive = @dwc.archive
      @path = @archive.files_path
      root_key = @archive.meta.keys[0]
      @data = @archive.meta[root_key][:core]
      unless @data
        raise DarwinCore::CoreFileError,
              "Cannot find core in meta.xml, is meta.xml valid?"
      end
      @id = @data[:id][:attributes]
      init_attributes
    end
  end
  # rubocop:enable Metrics/MethodLength
end
