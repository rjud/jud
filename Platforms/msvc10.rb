require 'cl10'
require 'win32'

class Msvc10 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      config['tools'] << 'cl10' << 'nmake'
      Jud::Config.instance.config['tools']['cl10']['type'] = Cl10.name
    end
    
    def configure_c_compiler
      Cl10.new.configure
    end
    
  end
  
end
