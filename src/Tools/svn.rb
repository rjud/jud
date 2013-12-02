require 'scm_tool'

class SVN < SCMTool
  
  def initialize url
    super('svn', url)
  end
  
  def checkout src
    cmd = '"' + path + '"'
    cmd += ' checkout'
    cmd += ' ' + @url + '/trunk'
    cmd += ' ' + src.basename.to_s
    $platform.execute cmd, src.dirname
  end
  
  def update src
    cmd = '"' + path + '"'
    cmd += ' update'
    $platform.execute cmd, src
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
    $platform.execute cmd, src.dirname
  end
  
  def copy src, dest
    cmd = '"' + path + '"'
    cmd += ' copy'
    cmd += ' -m "Create ' + dest + '"'
    cmd += ' ' + src.to_s
    cmd += ' ' + @url + dest
    $platform.execute cmd
  end
  
end
