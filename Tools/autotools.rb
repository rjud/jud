require 'build_tool'

class AutoTools < BuildTool
    
  attr_reader :native_build_tool
  
  def initialize
    super()
    platform = $platform_config['Native Build Tool']
    @native_build_tool = $platform.get_tool platform
  end
  
  def option_to_s opt
    case opt.type
    when :BOOLEAN then opt.value ? 'yes' : 'no'
    else opt.value
    end
  end
  
  def configure src, build, install, build_type, options={}
    cmd = "#{src}/configure -C"
    cmd += " --prefix=#{install.to_s}"    
    resolve_options(options).each do |opt|
      cmd += " #{opt.name}=#{option_to_s opt}"
    end
    if Platform.is_linux? and Platform.is_64? then
      cmd += " CPPFLAGS=-fPIC"
    end
    Platform.execute cmd, wd: build
  end
  
  def build *args
    @native_build_tool.build *args
  end
  
  def install *args
    @native_build_tool.install *args
  end
  
end
