require 'nmake'

class Mingw32 < Platform
  
  def initialize
    @cmake_native_build_tool = NMake.new
    @cmake_generator = "NMake Makefiles"
  end
  
  def variant; Platform::WIN32; end
  
  def autoconfigure
    # We are under Windows. Try to find a Visual compiler
    config = Jud::Config.instance.config['main']['default_platform']
    config['cmake_generator'] = 'NMake Makefiles'
  end
  
end
