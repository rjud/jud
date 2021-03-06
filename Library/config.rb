require 'configuration_file'
require 'pathname'
require 'singleton'
require 'yaml'

module Jud
  class Config
    include Singleton
    
    class Error < RuntimeError; end
    
    attr_accessor :config, :passwords
    attr_reader :config_file, :passwords_file
    
    def initialize()
      @config_file = Jud::ConfigurationFile.new('config.yml')
      @passwords_file = Jud::ConfigurationFile.new('password.yml')
      @config = @config_file.contents
      @passwords = @passwords_file.contents
      # Create some entries
      @config['main']['proxy']['host'] = '' if not @config['main']['proxy'].include? 'host'
      @config['main']['proxy']['port'] = '' if not @config['main']['proxy'].include? 'port'
      @config['main']['proxy']['exceptions'] = [] if not @config['main']['proxy'].include? 'exceptions'
      @config['main']['platform'] = 'default' if not @config['main'].include? 'platform'
      @config['main']['application'] = 'Tools' if not @config['main'].include? 'application'
      @config['main']['repositories']['default']['dir'] = Jud::ConfigurationFile.configdir.to_s
      @config['main']['repositories']['default']['home'] = nil
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
      @config_file.save()
      @passwords_file.save()
    end
    
  end
    
end
