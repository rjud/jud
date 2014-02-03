require 'build_tool'
require 'open3'

class CMake < BuildTool
  
  CMake.configure
  
  attr_reader :native_build_tool
  
  def initialize name
    super(name)
    @native_build_tool = $platform.get_tool $platform_config['Native Build Tool']
  end
  
  def option_to_s opt
    case opt.type
    when :BOOLEAN then opt.value ? 'ON' : 'OFF'
    else opt.value
    end
  end
  
  def configure src, build, install, build_type, options={}
    cmd = '"' + path + '"'
    cmd += ' -G "' + $platform_config['CMake Generator'] + '"' if $platform_config.include? 'CMake Generator'
    cmd += ' -DCMAKE_INSTALL_PREFIX=' + install.to_s
    cmd += ' -DCMAKE_BUILD_TYPE=' + build_type.to_s
    resolve_options(options).each do |opt|
      cmd += ' -D' + opt.name + '=' + (option_to_s opt)
    end
    cmd += ' ' + src.to_s
    $platform.execute cmd, wd: build
  end
  
  def build *args
    @native_build_tool.build *args
  end
  
  def install *args
    @native_build_tool.install *args
  end
  
end
