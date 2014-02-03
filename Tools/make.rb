require 'build_tool'

class Make < BuildTool
  
  class << self
    def name; return 'make'; end
    def autoconfigurable; return true; end
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
