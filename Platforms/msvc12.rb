require 'c'
require 'cxx'
require 'win32'

class Msvc12 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      config['tools'] = [] unless config.key? 'tools'
      config['tools'] << 'Cl12'
      config['tools'] << 'NMake12'
      config['runtime'] = 'MD'
      config['arch'] = 'x86'
    end
    
    def languages
      super + [Jud::Languages::C, Jud::Languages::Cxx]
    end
    
    def compiler
      require 'cl12'
      Cl12
    end
    
  end
  
  def initialize name
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "msvc12"; end
  
end
