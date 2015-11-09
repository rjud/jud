require 'tool'

module Jud::Tools
  class Patch < Tool
    
    def initialize options={}
      super options
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
end
