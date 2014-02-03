require 'config'

class Tool
  
  class << self
    
    attr_reader :path
    
    def variants; return [Platform::UNIX, Platform::WIN32]; end
        
    def load_path; return true; end
    
    def configure
      puts (Platform.blue "Configure #{self.name}")
      # Get the current configuration of this tool
      $platform_config['tools'][name] = name unless $platform_config['tools'].include? name
      config = $tools_config[$platform_config['tools'][name]]
      # Configure path of this tool if needed
      if load_path then
        configure_property config, 'path', lambda { $platform.find_executable name, optional=true }
        @path = get_directory config, 'path'
      end
      # Configure extra properties
      self.extra_configure config
    end
    
    def extra_configure config; end
    
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
        return Pathname.new value
      else
        return nil
      end
    end
    
  end
  
  attr_reader :name
  
  def initialize name
    @name = name
  end
  
  def path
    self.class.path.to_s
  end
  
end
