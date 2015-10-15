require 'c'
require 'cxx'
require 'win32'

class Msvc12 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      require 'cl12'
      config['tools'][Cl12.name] = Cl12.name
      config['runtime'] = 'MD'
    end
    
    def languages
      [Jud::C, Jud::Cxx]
    end
    
    def compiler
      require 'cl12'
      Cl12
    end
  
  end
  
  def initialize name
    require 'cl12'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "msvc12"; end
  
end
