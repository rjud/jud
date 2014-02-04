require 'scm_tool'

class Git < SCMTool
  
  class << self
    def guess url; return url.end_with? '.git' end
  end
  
  Git.configure
  
  def initialize name, url, options = {}
    super(name, url)
  end
  
  def checkout src, options = {}
    cmd = '"' + path + '"'
    cmd += " clone #{@url} #{src.basename.to_s}"
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def update src
    cmd = '"' + path + '"'
    #cmd += ' fetch'
    Platform.execute cmd, wd: src
  end
  
  def branch src, branch
    
  end
  
  def tag src, tag
    
  end
  
  def tags src
    cmd = '"' + path + '" tag'
    Platform.execute cmd, wd: src.dirname
  end
  
end
