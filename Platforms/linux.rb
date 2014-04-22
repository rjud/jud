require 'composite'
require 'c'
require 'cxx'

class Linux < Composite
  
  class << self
    
    def create config
      config['CMake Generator'] = 'Unix Makefiles'
      config['Native Build Tool'] = 'Make'
    end
    
    def languages
      [Jud::C, Jud::Cxx]
    end
    
  end
  
  def initialize name
    require 'make'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "gcc"; end
  
end
