require 'config'

class Tool
  
  class << self    
    def variants; return [Platform::UNIX, Platform::WIN32]; end
  end
  
  attr_reader :name
  
  def initialize name, load_path=true
    @name = name
    @load_path = load_path
    @path = nil
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
  
  def autoconfigure
    $tools_config[name]['type'] = self.class.name
    if @load_path then
      configure_directory :@path, 'path', lambda { $platform.find_executable name, optional=true }
    end
  end
  
  def load_env; end
  
  def configure_executable name
    path = $platform.find_executable name, optional = true
    if path then
      $general_config['tools'][self.class.name][name] = path
    end
  end
  
  def configure_property attr, prop, func1, func2
    value = instance_variable_get attr
    if value.nil? then
      value = func1.call
      puts (Platform.green "#{name}: set #{prop} to #{value}")
      $tools_config[name][prop] = func2.call value
      instance_variable_set attr, value
    end
    $tools_config[name][prop] = func2.call value
  end
  
  def configure_directory attr, prop, func
    configure_property attr, prop, func, lambda { |p| p.to_s }
  end
  
  def path
    if @path.nil? then
      if @load_path then
        @path = $tools_config[name]['path']
        if @path.nil? or @path.empty? then
          @path = $platform.find_executable self.class.name
        end
      else
        abort "No path for #{self.class.name}"
      end
    end
    return @path
  end
  
end
