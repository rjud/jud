require 'cl'

class Cl11 < Cl
  
  class << self
    
    def version; '11.0'; end
    
    def get_windows_sdk_dir
      return Pathname.new reg_query('SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.0', 'InstallationFolder')
    end
    
    def get_vs_common_tools_dir
      if ENV.key? 'VS110COMNTOOLS' then
        return ENV['VS110COMNTOOLS']
      else
        return get_vs_install_dir.join('Common7', 'Tools')
      end
    end
    
    def get_framework_dir
      dir = reg_query('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7', 'FrameworkDir32')
      ver = reg_query('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7', 'FrameworkVer32')
      return File.join(dir, ver)
    end
    
  end
  
  Cl11.configure
  
  def initialize config = {}
    super(config)
  end
  
end
