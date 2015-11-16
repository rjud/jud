load "Library/python.rb"

module Jud::Tools
  class Python < Jud::Compiler
    
    include Jud::Languages::Python
    
    def initialize config = {}
      super config
    end
    
  end
end
