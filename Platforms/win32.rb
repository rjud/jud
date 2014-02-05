require 'nmake'

module Jud
  class Win32 < Platform
    
    class << self
      
      def create config
        config['CMake Generator'] = 'NMake Makefiles'
        config['Native Build Tool'] = 'nmake'
      end
      
    end
    
    def variant; Platform::WIN32; end
    
  end
end
