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
  
  def checkout src, prj, options = {}
    # Login
    cmd = "\"#{path}\" -d#{@url} login -p \"\""
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
    # Check-out
    args = ''
    if options.has_key? :tag then
      args = " -r #{options[:tag]}"
    elsif options.has_key? :branch then
      args = " -r #{options[:branch]}"
    elsif options.has_key? :version then
      args = " -r #{options[:version]}"
    end
    cmd = "\"#{path}\" -z3 -d#{@url} co -P #{args} -d #{src.basename.to_s} #{modulename}"
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
