require 'nmake'

module Jud
  class Win32 < Platform
    
    class << self
      
      def create config
        config['CMake Generator'] = 'NMake Makefiles'
        config['Native Build Tool'] = 'nmake'
      end
      
    end
    
    def initialize
      @cmake_native_build_tool = NMake.new
      @cmake_generator = "NMake Makefiles"
    end
    
    def variant; Platform::WIN32; end
    
  end
end
