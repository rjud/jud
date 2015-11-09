require 'memcheck_tool'

module Jud::Tools
  class Valgrind < MemcheckTool
    
    class << self
      def variants; return [Platform::UNIX]; end
    end
    
    def initialize config={}
      super config
    end
    
  end
end
