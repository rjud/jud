require 'c'

class GCC < Jud::C::Compiler
  
  class << self
        
    def load_path; false; end
    
    def variants; return [Platform::UNIX]; end
    
    #def extra_configure config
    #end
        
  end
  
  def initialize config = {}
    super()
  end
  
end
