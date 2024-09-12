# frozen_string_literal: true

require "fileutils"
require "ostruct"
require "digest"
require "csv"
require "logger"
require "nokogiri"
require "biodiversity"
require_relative "dwc_archive/xml_reader"
require_relative "dwc_archive/ingester"
require_relative "dwc_archive/errors"
require_relative "dwc_archive/expander"
require_relative "dwc_archive/archive"
require_relative "dwc_archive/core"
require_relative "dwc_archive/extension"
require_relative "dwc_archive/metadata"
require_relative "dwc_archive/generator"
require_relative "dwc_archive/generator_meta_xml"
require_relative "dwc_archive/generator_eml_xml"
require_relative "dwc_archive/taxon_normalized"
require_relative "dwc_archive/gnub_taxon"
require_relative "dwc_archive/classification_normalizer"
require_relative "dwc_archive/version"

# main class for handling darwin core archives
class DarwinCore
  DEFAULT_TMP_DIR = "/tmp"
  VernacularNormalized = Struct.new(:name, :language, :locality, :country_code)
  SynonymNormalized = Struct.new(:id, :name, :canonical_name, :status, :source,
                                 :local_id, :global_id)

  class << self
    attr_writer :logger

    def clean(path)
      FileUtils.rm_rf(path) if FileTest.exist?(path)
    end

    def files(path)
      return nil unless path && FileTest.exist?(path)

      Dir.entries(path).reject { |e| e.match(/[.]{1,2}$/) }.sort
    end

    def random_path(tmp_dir)
      File.join(tmp_dir, "dwc_#{rand(10_000_000_000)}")
    end
  end

  attr_reader :archive, :core, :metadata, :classification_normalizer
  alias eml metadata

  def self.nil_field?(field)
    return true if [nil, "", "/N"].include?(field)

    false
  end

  def self.clean_all(tmp_dir = DEFAULT_TMP_DIR)
    Dir.entries(tmp_dir).each do |entry|
      path = File.join(tmp_dir, entry)
      FileUtils.rm_rf(path) if FileTest.directory?(path) && entry.match(/^dwc_\d+$/)
    end
  end

  def self.logger
    @logger ||= Logger.new(nil)
  end

  def self.logger_reset
    self.logger = Logger.new(nil)
  end

  def self.logger_write(obj_id, message, method = :info)
    logger.send(method, "|#{obj_id}|#{message}|")
  end

  def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
    @dwc_path = dwc_path
    @archive = DarwinCore::Archive.new(@dwc_path, tmp_dir)
    @core = DarwinCore::Core.new(self)
    @metadata = DarwinCore::Metadata.new(@archive)
    extensions
  end

  def file_name
    File.split(@dwc_path).last
  end

  def path
    File.expand_path(@dwc_path)
  end

  # generates a hash from a classification data with path to each node,
  # list of synonyms and vernacular names.
  def normalize_classification
    return nil unless parent_id?

    @classification_normalizer ||=
      DarwinCore::ClassificationNormalizer.new(self)
    @classification_normalizer.normalize
  end

  def parent_id?
    !@core.fields.join("|").
      downcase.match(/highertaxonid|parentnameusageid/).nil?
  end

  def checksum
    Digest::SHA1.hexdigest(File.read(@dwc_path))
  end

  def extensions
    return @extensions if @extensions

    root_key = @archive.meta.keys[0]
    ext = @archive.meta[root_key][:extension]
    return @extensions = [] unless ext

    ext = [ext] if ext.class != Array
    @extensions = ext.map { |e| DarwinCore::Extension.new(self, e) }
  end
end
