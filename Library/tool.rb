require 'config'

class Tool
  
  class << self
    
    def autoconfigurable; return false; end
    
    def autoconfigure
      autoconfigure_executable name
    end
    
    def autoconfigure_executable name
      path = $platform.find_executable name, optional=true
      if path then
        Jud::Config.instance.config['main']['default_platform'][name] = path
      end
    end
    
    def autoconfigure_directory name, dir
      if File.directory? dir then
        puts (Platform.green "Set #{name} to #{dir}")
        Jud::Config.instance.config['main']['default_platform'][name] = dir
      end
    end
    
    def variants; return [Platform::UNIX, Platform::WIN32]; end
    
  end    
  
  def initialize load_path=true
    @load_path = load_path
    @path = nil
  end
  
  def path
    if @path.nil? then
      if @load_path then
        @path = Jud::Config.instance.config['tools'][self.class.name]['path']
        if @path.nil? or @path.empty? then
          @path = $platform.find_executable self.class.name
          Jud::Config.instance.config['tools'][self.class.name]['path'] = @path
        end
      else
        abort "No path for #{self.class.name}"
      end
    end
    return @path
  end
  
end
