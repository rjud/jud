require 'c'
require 'cxx'
require 'Platforms/win32'

class Msvc14 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      config['tools'] = [] unless config.key? 'tools'
      config['tools'] << 'Cl14'
      config['tools'] << 'NMake14'
      config['runtime'] = 'MD'
      config['arch'] = 'x86'
    end
    
    def languages
      super + [Jud::Languages::C, Jud::Languages::Cxx]
    end
    
    def compiler
      require 'Tools/cl14'
      Cl14
    end
  
  end
  
  def initialize name
    require 'Tools/cl14'
    super(name)
  end
  
  def build_name; "#{$platform.build_name}-#{short_build_name}"; end
  def short_build_name; "msvc14"; end
  
end
