require 'c'
require 'cxx'
require 'win32'

class Msvc10 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      require 'cl10'
      config['tools'][Cl10.name] = Cl10.name
      config['runtime'] = 'MD'
    end
    
    def languages
      super + [Jud::C, Jud::Cxx]
    end
    
    def compiler
      require 'cl10'
      Cl10
    end
  
  end
  
  def initialize name
    require 'cl10'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "msvc10"; end
  
end
