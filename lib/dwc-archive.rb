# encoding: UTF-8
$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))   
require 'ruby_extensions'
require 'dwc-archive/expander'
require 'dwc-archive/archive'
require 'dwc-archive/core'
require 'dwc-archive/extension'
require 'dwc-archive/metadata'

class DarwinCore
  attr_reader :archive, :core, :metadata, :extensions
  alias :eml :metadata
  def initialize(dwc_path, tmp_dir = "/tmp")
    @archive = DarwinCore::Archive.new(dwc_path, tmp_dir) 
    @core = DarwinCore::Core.new(@archive)
    @metadata = DarwinCore::Metadata.new(@archive)
    @extensions = get_extensions
  end
  private
  def get_extensions
    res = []
    root_key = @archive.meta.keys[0]
    ext = @archive.meta[root_key][:extension]
    return [] unless ext
    ext = [ext] unless ext.class == Array
    ext.map {|e| DarwinCore::Extension.new(@archive, e)}
  end
end
