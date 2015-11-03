require 'tool'

class SubmitTool < Tool
  
  OK = 0
  TESTS_NOK = 1
  BUILD_NOK = 2
  CONF_NOK = 3
  NOK = 4
  
  EXPERIMENTAL = 0
  NIGHTLY = 1
  CONTINUOUS = 2
  
  attr_accessor :build_tool, :scm_tool
  
  def initialize
    super()
  end
  
end
