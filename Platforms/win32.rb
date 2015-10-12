require 'composite'
require 'java'

module Jud
  class Win32 < Composite
    
    class << self
      
      def create config
        config['CMake Generator'] = 'NMake Makefiles'
        config['Native Build Tool'] = 'NMake'
      end
	  
      def languages
        [Jud::Java]
      end
      
    end
    
    def variant; Platform::WIN32; end
    
    def initialize name
      require 'nmake'
    end
    
  end
end
