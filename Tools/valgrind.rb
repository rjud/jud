require 'memcheck_tool'

class Valgrind < MemcheckTool
  
  class << self
    def variants; return [Platform::UNIX]; end
  end
  
  def initialize
    super()
  end
  
end
