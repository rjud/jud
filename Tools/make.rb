require 'build_tool'

class Make < BuildTool
  
  Make.configure
  
  def initialize options = {}
    super()
  end
  
  def build build, options = {}
    cmd = '"' + path + '"'
    mono = (options.has_key? :mono) and options[:mono]
    cmd += ' -j3' if Platform.is_linux? and not mono
    cmd += " #{options[:target]}" if options.has_key? :target
    Platform.execute cmd, wd: build
  end
  
  def install build
    cmd = '"' + path + '" install'
    Platform.execute cmd, wd: build
  end
  
end
