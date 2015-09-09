require 'build_tool'

class Make < BuildTool
  
  Make.configure
  
  def initialize options = {}
    super()
  end

  def build_command_line build, options
    cmd = '"' + path + '"'
    mono = (options.has_key? :mono) and options[:mono]
    cmd += ' -j3' if Platform.is_linux? and not mono
    cmd += " #{options[:target]}" if options.has_key? :target
    cmd
  end
  
  def build builddir, options = {}
    Platform.execute (build_command_line builddir, options), wd: builddir
  end
  
  def install builddir, options = {}
    fast = (options.has_key? :fast) and options[:fast]
    cmd = '"' + path + '" install' + ('/fast' if fast)
    Platform.execute cmd, wd: builddir
  end
  
end
