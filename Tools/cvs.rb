require 'scm_tool'

class CVS < SCMTool
  
  class << self
    def guess url; return url.start_with? ':pserver' end
  end
  
  CVS.configure
  
  attr_reader :modulename
  
  def initialize url, modulename, options={}
    super(url)
    @modulename = modulename
  end
  
  def checkout src, version, options = {}
    # Login
    cmd = '"' + path + '"'
    cmd += " -d#{@url} login -p \"\""
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
    # Check-out
    cmd = '"' + path + '"'
    cmd += " -z3 -d#{@url} co -P -d #{src.basename.to_s} #{modulename}"
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def update src
    
  end
  
  def branch src, branch
    
  end
  
  def tag src, tag
    
  end
  
  def tags src
    
  end
  
end
