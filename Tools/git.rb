require 'scm_tool'

class Git < SCMTool
  
  def initialize url
    super('git', url)
  end
  
  def checkout src
    cmd = '"' + path + '"'
    cmd += " clone #{@url} #{src.basename.to_s}"
    $platform.execute cmd, src.dirname
  end
  
  def update src
    cmd = '"' + path + '"'
    #cmd += ' fetch'
    $platform.execute cmd, src
  end
  
  def branch src, branch
    
  end
  
  def tag src, tag
    
  end
  
  def tags src
    cmd = '"' + path + '" tag'
    $platform.execute cmd, src.dirname
  end
  
end
