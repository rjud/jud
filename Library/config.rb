require 'pathname'
require 'singleton'
require 'YAML'

module Jud
  class Config
    include Singleton
    
    attr_accessor :config
    attr_reader :filename, :prefix
    
    def initialize
      @prefix = Pathname.new(Dir.home)
      configdir = @prefix.join('.jud')
      Dir.mkdir configdir.to_s if not File.directory? configdir.to_s
      @filename = configdir.join('config.yml')
      if File.exist? @filename
        puts Platform.green("Load config file " + @filename.to_s)
        raw = File.read(@filename)
        @config = YAML.load(raw)
      else
        @config = {}
      end
      # If a key does not exist, create it with a hash as value
      @config.default_proc = proc do |hash, key|
        hash[key] = Hash.new{ |h,k| h[k] = Hash.new &h.default_proc }
      end
      # On all hashes, set the previous proc
      iterate_on_hash = lambda do |h|
        if h.instance_of? Hash then
          h.default_proc = @config.default_proc
          h.each_value { |v| iterate_on_hash.call v }
        end
      end
      iterate_on_hash.call @config
      # Set some values
      if not @config['applications'].include? 'separate_install_trees' then
        @config['applications']['separate_install_trees'] = true
      end
    end
    
    def save
      File.open(@filename, 'w') do |out|
        YAML.dump(@config, out)
      end
    end
    
  end
end
