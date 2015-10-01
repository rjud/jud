require 'python'

class Python2 < Jud::Python::Compiler
  
  class << self
    
    def extra_configure config
    end
    
  end
  
  Python2.configure
  
  def initialize config = {}
    super()
  end
  
end
