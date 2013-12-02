require 'memcheck_tool'

class Valgrind < MemcheckTool
  
  def initialize
    super('valgrind')
  end
  
end
