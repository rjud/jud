require 'c'
require 'cxx'
require 'win32'

class Msvc11 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      require 'cl11'
      config['tools'][Cl11.name] = Cl11.name
      config['runtime'] = 'MD'
    end
    
    def languages
      super + [Jud::C, Jud::Cxx]
    end
    
    def compiler
      require 'cl11'
      Cl11
    end
  
  end
  
  def initialize name
    require 'cl11'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "msvc11"; end
  
end
