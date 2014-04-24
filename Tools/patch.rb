require 'tool'

class Patch < Tool
  
  Patch.configure
  
  def initialize options = {}
    super()
  end
  
  def patch srcdir, file
    cmd = "\"#{path}\" -p1 < #{file}"
    Platform.execute cmd, wd: srcdir
  end
  
end
