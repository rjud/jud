require 'nmake'

class Mingw32 < Platform
  
  def initialize
    @cmake_native_build_tool = NMake.new
    @cmake_generator = "NMake Makefiles"
  end
  
end
