require 'scm_tool'

class Git < SCMTool
  
  class << self
    def guess url; return url.end_with? '.git' end
  end
  
  Git.configure
  
  def initialize url, options={}
    super(url)
  end
  
  def checkout src, options = {}
    args = ''
    args += "-b #{options[:tag]} " if options.has_key? :tag
    cmd = "\"#{path}\" clone #{args} #{@url} #{src.basename.to_s}"
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def update src
    cmd = "\"#{path}\" pull"
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
