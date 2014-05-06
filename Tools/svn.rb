require 'scm_tool'

class SVN < SCMTool
  
  SVN.configure
  
  def initialize url, options = {}
    super(url, options)
  end
  
  def resolve_url options={}
    if options.has_key? :trunk then
      url = @url + '/trunk/'
    elsif options.has_key? :branch then
      url = @url + '/branches/' + options[:branch]
    elsif options.has_key? :tag then
      url = @url + '/tags/' + options[:tag]
    elsif options.has_key? :version then
      url = @url + '/tags/' + options[:version]
    else
      url = @url + '/trunk/'
    end
  end
  
  def checkout src, options = {}
    url = resolve_url options
    cmd = "\"#{path}\" checkout"
    cmd += " #{@options[:args]}" if @options.has_key? :args
    cmd += " -r #{options[:rev]}" if options.has_key? :rev
    cmd += " #{url} #{src.basename.to_s}"
    Platform.execute cmd, {:wd => src.dirname}.merge(options)
  end
  
  def get_revision src, options = {}
    dir = File.dirname path
    bin = File.join(dir, 'svnversion')
    cmd = "#{bin}"
    exit_status = Platform.execute cmd, {:wd => src, :keep => '[0-9a-z]'}.merge(options)
    exit_status[1].last
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
