# encoding: UTF-8
$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
R19 = RUBY_VERSION.split('.')[0..1].join('').to_i > 18
require 'fileutils'
require 'ostruct'

if R19
  require 'csv'
else
  require 'fastercsv'
  CSV = FasterCSV
  if (defined?(Rails) && Rails::VERSION::MAJOR >= 3 && Rails.env.test?)
    $" << 'csv.rb'
  end
end

require 'logger'
require 'dwc-archive/xml_reader'
require 'dwc-archive/ingester'
require 'dwc-archive/errors'
require 'dwc-archive/expander'
require 'dwc-archive/archive'
require 'dwc-archive/core'
require 'dwc-archive/extension'
require 'dwc-archive/metadata'
require 'dwc-archive/generator'
require 'dwc-archive/generator_meta_xml'
require 'dwc-archive/generator_eml_xml'
require 'dwc-archive/classification_normalizer'

class DarwinCore

  VERSION = open(File.join(File.dirname(__FILE__), '..', 'VERSION')).readline.strip

  attr_reader :archive, :core, :metadata, :extensions, :classification_normalizer
  alias :eml :metadata

  DEFAULT_TMP_DIR = "/tmp"

  def self.nil_field?(field)
    return true if [nil, '', '/N'].include?(field)
    false
  end

  def self.clean_all(tmp_dir = DEFAULT_TMP_DIR)
    Dir.entries(tmp_dir).each do |entry|
      path = File.join(tmp_dir, entry)
      if FileTest.directory?(path) && entry.match(/^dwc_[\d]+$/)
        FileUtils.rm_rf(path)
      end
    end
  end

  def self.logger
    @@logger ||= Logger.new(nil)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger_reset
    self.logger = Logger.new(nil)
  end

  def self.logger_write(obj_id, message, method = :info)
    self.logger.send(method, "|%s|%s|" % [obj_id, message])
  end

  def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
    @dwc_path = dwc_path
    @archive = DarwinCore::Archive.new(@dwc_path, tmp_dir)
    @core = DarwinCore::Core.new(self)
    @metadata = DarwinCore::Metadata.new(@archive)
    @extensions = get_extensions
  end

  # generates a hash from a classification data with path to each node, list of synonyms and vernacular names.
  def normalize_classification
    return nil unless has_parent_id?
    @classification_normalizer ||= DarwinCore::ClassificationNormalizer.new(self)
    @classification_normalizer.normalize
  end

  def has_parent_id?
    !!@core.fields.join('|').downcase.match(/highertaxonid|parentnameusageid/)
  end

  def checksum
    Digest::SHA1.hexdigest(open(@dwc_path).read)
  end

  private
  def get_extensions
    res = []
    root_key = @archive.meta.keys[0]
    ext = @archive.meta[root_key][:extension]
    return [] unless ext
    ext = [ext] if ext.class != Array
    ext.map { |e| DarwinCore::Extension.new(self, e) }
  end
end
