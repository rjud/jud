require 'linux'

class CentOS6 < Linux
  
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
  
  def short_build_name; "centos6"; end
  
end
