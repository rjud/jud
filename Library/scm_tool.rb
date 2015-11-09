require 'set'
require 'tool'

class SCMTool < Tool
  
  class << self
    def guess url; return false; end
  end
  
  attr_reader :url
  
  def initialize url=nil, options={}
    super options
    @url = url
  end
  
end
