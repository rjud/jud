require 'cl'

# To use .NET, add
# FrameworkDir, FrameworkVer => read key SxS\VC7
# C:\\WINDOWS\\Microsoft.NET\\Framework\\v4.0.30319
# Concatenate v3.5 to FrameworkDir
# C:\\WINDOWS\\Microsoft.NET\\Framework\\v3.5
# Concatenate WindowsSdkDir to bin\NETFX 4.0 Tools
# C:\\Program Files\\Microsoft SDKs\\Windows\\v7.0A\\bin\\NETFX 4.0 Tools"

class Cl10 < Cl
  
  class << self
    
    def version; '10.0'; end
    
    def get_windows_sdk_dir
      return Pathname.new reg_query('SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0A', 'InstallationFolder')
    end
    
    def get_vs_common_tools_dir
      if ENV.key? 'VS100COMNTOOLS' then
        return ENV['VS100COMNTOOLS']
      else
        return get_vs_install_dir.join('Common7', 'Tools')
      end
    end
    
  end
  
  Cl10.configure
  
  def initialize config = {}
    super(config)
  end
  
end
