# encoding: UTF-8
$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))   
require 'ruby_extensions'
require 'fileutils'
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
    ext = [ext] unless ext.class == Array
    ext.map { |e| DarwinCore::Extension.new(@archive, e) }
  end
end
