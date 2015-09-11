require 'build_tool'

class Make < BuildTool
  
  Make.configure
  
  def initialize options = {}
    super()
  end
  
  def build_command_line options
    cmd = '"' + path + '"'
    mono = (options.has_key? :mono) and options[:mono]
    cmd += ' -j3' if Platform.is_linux? and not mono
    cmd += " #{options[:target]}" if options.has_key? :target
    cmd
  end
  
  def execute rule, options
    cmd = build_command_line (if rule.nil? then options else options.merge({ :target => rule }) end)
    Platform.execute cmd, options
  end
  
  def build builddir, options = {}
    execute nil, options.merge({ :wd => builddir })
  end
  
  def install builddir, options = {}
    fast = (options.has_key? :fast) and options[:fast]
    rule = 'install' + (fast ? '/fast' : '')
    execute rule, options.merge({ :wd => builddir })
  end
  
end
