require 'Tool'

class SubmitTool < Tool
  
  OK = 0
  TESTS_NOK = 1
  BUILD_NOK = 2
  CONF_NOK = 3
  NOK = 4
  
  attr_accessor :build_tool, :scm_tool
  
end
