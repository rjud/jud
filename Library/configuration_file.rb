require 'pathname'
require 'singleton'
require 'yaml'

module Jud
  class ConfigurationFile
    
    class Error < RuntimeError; end
    
    class << self
      def configdir
        (Pathname.new Dir.home).join '.jud'
      end
    end
    
    attr_accessor :contents
    attr_reader :filename #, :prefix
    
    def initialize(filename)
      configdir = ConfigurationFile.configdir
      Dir.mkdir configdir.to_s if not File.directory? configdir.to_s
      @filename = configdir.join(filename)
      if File.exist? @filename
        puts Platform.green("Load config file " + @filename.to_s)
        raw = File.read(@filename)
        @contents = YAML.load(raw)
      else
        @contents = {}
      end
      # If a key does not exist, create it with a hash as value
      @contents.default_proc = proc do |hash, key|
        hash[key] = Hash.new{ |h,k| h[k] = Hash.new &h.default_proc }
      end
      # On all hashes, set the previous proc
      iterate_on_hash = lambda do |h|
        if h.instance_of? Hash then
          h.default_proc = @contents.default_proc
          h.each_value { |v| iterate_on_hash.call v }
        end
      end
      iterate_on_hash.call @contents
    end
        
    def save
      File.open(@filename, 'w') do |out|
        YAML.dump(@contents, out)
      end
      File.new(@filename).chmod(0600)
    end
    
  end
end
