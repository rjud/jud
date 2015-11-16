require 'config'

class Tool
  
  class Error < RuntimeError; end
  
  class << self
    
    attr_reader :path
    
    def projectname; name; end
    def toolname klass
      if /^Jud::Tools::(?<myname>.*)$/ =~ klass.name
        myname
      else
        nil
      end
    end
    
    def variants; return [Platform::UNIX, Platform::WIN32]; end
    
    def load_path; return true; end
    def pure_ruby; return false; end
    
    #def get_tool_configuration name
    #  $tools_config[name]
    #end
    
    #def get_tool_configurations klass
    #  $tools_config.each do |name, configuration|
    #    tlname = (configuration.key? 'instanceof') ? configuration['instanceof'] : name
    #  end
    #end
    
    #def get_passwords
    #  if $platform_config then
    #    unless $platform_config['tools'].include? name then
    #      $platform_config['tools'][name] = name
    #    end
    #    return $tools_passwords[$platform_config['tools'][name]]
    #  else
    #    return $tools_passwords[name]
    #  end
    #end
    
    def configure name=nil, exe=nil
      tlname = name.nil? ? (toolname self) : name
      unless tlname.nil? then
        exename = exe.nil? ? tlname.downcase : exe
        Platform.find_executables(exename).each do |path|
          Platform.putfinds tlname, path
          save_config_property tlname, 'path', path    
        end
      end
    end
    
    def oldconfigure
      puts (Platform.blue "Configure #{self.name}")
      # Get the current configuration of this tool
      config = get_config
      passwords = get_passwords
      # Configure path of this tool if needed
      if load_path then
        configure_property config, 'path', lambda {
          path = Platform.find_executable basename, optional=true
          if path.nil? then
            puts (Platform.red "Can't find #{name}. I will compile it for you")
            begin
              Application.build 'Tools', projectname
            rescue Exception => e
              puts (Platform.red "I can't compile it. I am giving up !")
              puts (Platform.red e)
              for l in e.backtrace
                puts (Platform.red l)
              end
              return
            end
            add_to_path = project(projectname.to_sym).prefix.to_s
            add_to_path2 = project(projectname.to_sym).prefix.join('bin').to_s
            if Platform.is_windows? then
              ENV['PATH'] = add_to_path << ";" << add_to_path2 << ";" << ENV['PATH']
            else
              ENV['PATH'] = add_to_path << ":" << add_to_path2 << ":" << ENV['PATH']
            end
            puts "PATH: #{ENV['PATH']}"
            path = Platform.find_executable basename, optional=true
            puts path
          end
          path
        }
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
    
    def get_configuration toolname
      unless $tools_config.include? toolname
        $tools_config[toolname]['instanceof'] = toolname self
      end
      if $tools_config[toolname].nil? or $tools_config[toolname].empty?
        $tools_config[toolname]['instanceof'] = toolname self
      end
      $tools_config[toolname]
    end
    
    def save_config_property toolname, name, value
      config = get_configuration toolname
      old_value = config[name]
      new_value = value.to_s
      if new_value != old_value
        config[name] = new_value
        puts (Platform.green "Set #{toolname}.#{name} to #{config[name]}")
      end
    end
    
  end
  
  attr_reader :path, :config, :passwords, :options, :name, :version
  
  def initialize options={}
    (name, config) = $platform.get_tool_config (Tool.toolname self.class)
    config = config.merge ({ :options => options })
    @name = name
    @config = config
    #@passwords = self.class.get_passwords
    @options = options
    @path = (@config.key? 'path') ? @config['path'] : nil
  end
  
  def setenv context
    context.appenv 'PATH', (File.dirname @path)
  end
  
end
