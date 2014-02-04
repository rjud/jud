require 'build_tool'

class Make < BuildTool
  
  Make.configure
  
  def initialize name
    super(name)
  end
  
  def build build
    cmd = '"' + path + '"'
    Platform.execute cmd, wd: build
  end
  
  def install build
    cmd = '"' + path + '" install'
    Platform.execute cmd, wd: build
  end
  
end
