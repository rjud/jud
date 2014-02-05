require 'make'

class Darwin < Platform
  
  class << self
    
    def create config
      config['CMake Generator'] = 'Unix Makefiles'
      config['Native Build Tool'] = 'Make'
    end
    
  end
  
  def variant; Platform::UNIX; end
  
end
