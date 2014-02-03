require 'Tool'

module Jud
  class Compiler < Tool
    
    def initialize name, load_path=false
      super(name, load_path)
    end
    
  end
end
