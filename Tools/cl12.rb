require 'cl'

class Cl12 < Cl
  
  class << self
    
    def version; '12.0'; end
    
    def get_windows_sdk_dir
      return Pathname.new reg_query('SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.1', 'InstallationFolder')
    end
    
    def get_vs_common_tools_dir
      if ENV.key? 'VS120COMNTOOLS' then
        return ENV['VS120COMNTOOLS']
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
  
  Cl12.configure
  
  def initialize config = {}
    super(config)
  end
  
end
