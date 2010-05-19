# encoding: UTF-8
$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))   
require 'ruby_extensions'
require 'fileutils'
begin
  require 'fastercsv'
  CSV = FasterCSV
rescue LoadError
  require 'csv'
end
require 'dwc-archive/ingester'
require 'dwc-archive/errors'
require 'dwc-archive/expander'
require 'dwc-archive/archive'
require 'dwc-archive/core'
require 'dwc-archive/extension'
require 'dwc-archive/metadata'

class DarwinCore
  attr_reader :archive, :core, :metadata, :extensions
  alias :eml :metadata
  
  DEFAULT_TMP_DIR = "/tmp"
  UTF8RGX = /\A(
        [\x09\x0A\x0D\x20-\x7E]            # ASCII
      | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
      |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
      | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
      |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
      |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
      | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
      |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
    )*\z/x unless defined? UTF8RGX

  
  def initialize(dwc_path, tmp_dir = DEFAULT_TMP_DIR)
    @archive = DarwinCore::Archive.new(dwc_path, tmp_dir) 
    @core = DarwinCore::Core.new(@archive)
    @metadata = DarwinCore::Metadata.new(@archive)
    @extensions = get_extensions
  end

  def self.clean_all(tmp_dir = DEFAULT_TMP_DIR)
    Dir.entries(tmp_dir).each do |entry|
      path = File.join(tmp_dir, entry)
      if FileTest.directory?(path) && entry.match(/^dwc_[\d]+$/)
        FileUtils.rm_rf(path)
      end
    end
  end

  private
  def get_extensions
    res = []
    root_key = @archive.meta.keys[0]
    ext = @archive.meta[root_key][:extension]
    return [] unless ext
    ext = [ext] if ext.class != Array
    ext.map { |e| DarwinCore::Extension.new(@archive, e) }
  end
end
