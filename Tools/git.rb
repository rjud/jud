require 'scm_tool'

class Git < SCMTool
  
  class << self
    def name; return 'git'; end
    def autoconfigurable; return true; end
    def guess url; return url.end_with? '.git' end
  end
  
  def initialize url
    super(url)
  end
  
  def checkout src, options = {}
    cmd = '"' + path + '"'
    cmd += " clone #{@url} #{src.basename.to_s}"
    $platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def update src
    cmd = '"' + path + '"'
    #cmd += ' fetch'
    $platform.execute cmd, wd: src
  end
  
  def branch src, branch
    
  end
  
  def tag src, tag
    
  end
  
  def tags src
    cmd = '"' + path + '" tag'
    $platform.execute cmd, wd: src.dirname
  end
    
end
