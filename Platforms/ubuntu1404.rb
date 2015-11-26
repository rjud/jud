require 'Platforms/linux'

class Ubuntu1404 < Linux
  
  class << self
    
    def create config
      Linux.create config
    end
    
    def languages
      Linux.languages
    end
    
  end
  
  def initialize name
    super(name)
  end
  
  def short_build_name; "ubuntu-14.04"; end
  
end
