require 'build_tool'

class Make < BuildTool
  
  def initialize name='make'
    super(name)
  end
  
  def build build
    cmd = '"' + path + '"'
    $platform.execute cmd, build
  end
  
  def install build
    cmd = '"' + path + '" install'
    $platform.execute cmd, build
  end
  
end
