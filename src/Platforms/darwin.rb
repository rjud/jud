require 'make'

class Darwin < Platform
  
  def initialize
    @cmake_native_build_tool = Make.new
    @cmake_generator = "Unix Makefiles"
  end
  
end
