require 'c'
require 'cxx'
require 'compiler'

module Jud::Tools
  class GCC < Jud::Compiler
    
    include Jud::Languages::C
    include Jud::Languages::Cxx
    
    class << self
      def variants; return [Platform::UNIX]; end    
    end
    
    def initialize config={}
      super config
    end
    
  end
end
