require 'make'

class Darwin < Platform
  
  class << self
    
    def create config
      config['CMake Generator'] = 'Unix Makefiles'
      config['Native Build Tool'] = 'Make'
    end
    
  end
  
  #def initialize
  #  @cmake_native_build_tool = Make.new
  #  @cmake_generator = "Make Makefiles"
  #end
  
  def variant; Platform::UNIX; end
  
end
