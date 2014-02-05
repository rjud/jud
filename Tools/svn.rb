require 'scm_tool'

class SVN < SCMTool
  
  SVN.configure
  
  def initialize options = {}
    super(url)
  end
  
  def checkout src, options = {}
    cmd = '"' + path + '"'
    cmd += ' checkout'
    cmd += ' ' + @url + '/trunk'
    cmd += ' ' + src.basename.to_s
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def update src
    cmd = '"' + path + '"'
    cmd += ' update'
    Platform.execute cmd, wd: src
  end
  
  def branch src, branch
    copy src, '/branches/' + branch
  end
  
  def tag src, tag
    copy src, '/tags/' + tag
  end
  
  def tags src
    cmd = '"' + path + '"'
    cmd += ' ls ' + @url + '/tags'
    Platform.execute cmd, wd: src.dirname
  end
  
  def copy src, dest
    cmd = '"' + path + '"'
    cmd += ' copy'
    cmd += ' -m "Create ' + dest + '"'
    cmd += ' ' + src.to_s
    cmd += ' ' + @url + dest
    Platform.execute cmd
  end
  
end
