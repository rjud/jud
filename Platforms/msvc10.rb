require 'cl10'
require 'win32'

class Msvc10 < Jud::Win32
  
  class << self
    
    def create config
      Jud::Win32.create config
      config['tools'][Cl10.name] = Cl10.name
    end
    
    def configure_c_compiler
      Cl10.new.configure
    end
    
  end
  
end
