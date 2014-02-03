require 'set'
require 'Tool'

class SCMTool < Tool
    
  class << self
    def guess url; return false; end
  end
  
  attr_reader :url
  
  def initialize url
    super
    @url = url
  end
    
end
