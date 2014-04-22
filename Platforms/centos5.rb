require 'linux'

class CentOS5 < Linux
  
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
  
  def short_build_name; "centos5"; end
  
end
