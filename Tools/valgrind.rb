require 'memcheck_tool'

class Valgrind < MemcheckTool
  
  class << self
    def name; 'valgrind'; end
    def autoconfigurable; return true; end
    def variants; return [Platform::UNIX]; end
  end
  
end
