require 'tool'

class Patch < Tool
  
  Patch.configure
  
  def initialize options = {}
    super()
  end
  
  def patch srcdir, file
    arguments = file.split('.')
    cmd = "\"#{path}\" -p#{arguments[2]} < #{file}"
    begin
      Platform.execute cmd, wd: srcdir
    rescue
      # Try to convert EOL
    end
  end
  
end
