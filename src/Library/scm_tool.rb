require 'Tool'

class SCMTool < Tool
  
  attr_reader :url
  
  def initialize name, url
    super(name)
    @url = url
  end
  
end
