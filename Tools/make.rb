require 'build_tool'

class Make < BuildTool
  
  Make.configure
  
  def initialize options = {}
    super()
  end
  
  def build build
    cmd = '"' + path + '"'
    cmd += ' -j3' if Platform.is_linux?
    Platform.execute cmd, wd: build
  end
  
  def install build
    cmd = '"' + path + '" install'
    Platform.execute cmd, wd: build
  end
  
end
