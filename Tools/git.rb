require 'scm_tool'

class Git < SCMTool
  
  class << self
    def guess url; return url.end_with? '.git' end
  end
  
  Git.configure
  
  def initialize url, options={}
    super(url, options)
  end
  
  def checkout src, prj, options = {}
    cmd = "\"#{path}\" clone"
    cmd += " #{@options[:args]}" if @options.has_key? :args
    cmd += " #{@url} #{src.basename.to_s}"
    Platform.execute cmd, {:wd => src.dirname}.merge(options)

    if options.has_key? :tag then
      cmd = "\"#{path}\" checkout #{options[:tag]}"
      Platform.execute cmd, {:wd => src}.merge(options)
    end
  end
  
  def get_revision src, options = {}
    cmd = "\"#{path}\" describe --always"
    exit_status = Platform.execute cmd, {:wd => src, :keep => '[0-9a-f]'}.merge(options)
    exit_status[1].last
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
