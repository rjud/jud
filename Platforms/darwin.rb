require 'c'
require 'cxx'
require 'composite'

class Darwin < Composite
  
  class << self
    
    def create config
      config['CMake Generator'] = 'Unix Makefiles'
      config['Native Build Tool'] = 'Make'
    end
    
    def languages
      [Jud::C, Jud::Cxx]
    end
    
    def compiler
      require 'gcc'
      GCC
    end
    
  end
  
  def initialize name
    require 'make'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}"; end
  def short_build_name; ""; end
  
end
