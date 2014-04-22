require 'config'

class Tool
  
  class Error < RuntimeError; end
  
  class << self
    
    attr_reader :path
    
    def basename; name.downcase; end
    
    def variants; return [Platform::UNIX, Platform::WIN32]; end
        
    def load_path; return true; end
    
    def get_config
      if $platform_config then
        unless $platform_config['tools'].include? name then
          $platform_config['tools'][name] = name
        end
        return $tools_config[$platform_config['tools'][name]]
      else
        return $tools_config[name]
      end
    end
    
    def configure
      puts (Platform.blue "Configure #{self.name}")
      # Get the current configuration of this tool
      config = get_config
      # Configure path of this tool if needed
      if load_path then
        configure_property config, 'path', lambda { Platform.find_executable basename, optional=true }
        @path = get_directory config, 'path'
      end
      # Configure extra properties
      self.extra_configure config
    end
    
    def extra_configure config; end
    
    def configured?
      if load_path and @path
        return File.executable? @path
      elsif load_path then
        return false
      else
        return true
      end
    end
    
    def configure_property config, name, func
      if config[name].nil? or config[name].empty? then
        config[name] = func.call
        puts (Platform.green "Set #{name} to #{config[name]}") unless config[name].nil?
      end
    end
    
    def configure_directory config, name, func
      configure_property config, name, lambda { func.call.to_s }
    end
    
    def get_property config, name
      if config.include? name then
        config[name]
      else
        nil
      end
    end
    
    def get_directory config, name
      value = get_property config, name
      if value then
        return value
      else
        return nil
      end
    end
    
  end
  
  attr_reader :config, :options
  
  def initialize options={}
    @config = self.class.get_config
    @options = options
  end
  
  def path
    self.class.path.to_s
  end
  
end
