require 'pathname'
require 'singleton'
require 'YAML'

module Jud
  class Config
    include Singleton
    
    class Error < RuntimeError; end
    
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
      # Create some entries
      if not @config.include? 'main' then
        @config['main']['proxy']['host'] = ''
        @config['main']['proxy']['port'] = ''
        @config['main']['proxy']['exceptions'] = []
      end
    end
    
    def get_repo_config repository
      config = @config['main']['repositories']
      if not config.include? repository then
        raise Error, "No repository #{repository}"
      end
      return config[repository]
    end
    
    def get_platform_config platform
      config = @config['platforms']
      if not config.include? platform then
        raise Error, "No platform #{platform}"
      end
      return config[platform]
    end
    
    def save
      File.open(@filename, 'w') do |out|
        YAML.dump(@config, out)
      end
    end
    
  end
end
