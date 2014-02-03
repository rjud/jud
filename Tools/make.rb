require 'build_tool'

class Make < BuildTool
  
  class << self
    def autoconfigurable; return true; end
  end
  
  def initialize name
    super(name)
  end
  
  def build build
    cmd = '"' + path + '"'
    $platform.execute cmd, wd: build
  end
  
  def install build
    cmd = '"' + path + '" install'
    $platform.execute cmd, wd: build
  end
  
end
