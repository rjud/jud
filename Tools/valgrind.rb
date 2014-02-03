require 'memcheck_tool'

class Valgrind < MemcheckTool
  
  class << self
    def autoconfigurable; return true; end
    def variants; return [Platform::UNIX]; end
  end
  
  def initialize name
    super(name)
  end
  
end
