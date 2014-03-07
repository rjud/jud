require 'build_tool'
require 'open3'

class CMake < BuildTool
  
  CMake.configure
  
  attr_reader :native_build_tool
  
  def initialize
    super()
    platform = $platform_config['Native Build Tool']
    @native_build_tool = $platform.get_tool platform
  end
  
  def option_to_s opt
    case opt.type
    when :BOOLEAN then opt.value ? 'ON' : 'OFF'
    else opt.value
    end
  end
  
  def configure src, build, install, build_type, options={}
    cmd = '"' + path + '"'
    if $platform_config.include? 'CMake Generator' then
      cmd += ' -G "' + $platform_config['CMake Generator'] + '"' 
    end
    cmd += ' -DCMAKE_INSTALL_PREFIX=' + install.to_s
    cmd += ' -DCMAKE_BUILD_TYPE=' + build_type.to_s
    if Platform.is_linux? and Platform.is_64? then
      cmd += ' -DCMAKE_CXX_FLAGS=-fPIC'
    end
    resolve_options(options).each do |opt|
      cmd += ' -D' + opt.name + '=' + (option_to_s opt)
    end
    cmd += ' ' + src.to_s
    Platform.execute cmd, wd: build
  end
  
  def build *args
    @native_build_tool.build *args
  end
  
  def install *args
    @native_build_tool.install *args
  end
  
end
