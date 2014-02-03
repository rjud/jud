require 'c'
require 'win32/registry'

class Cl < Jud::C::Compiler
  
  class << self
        
    def variants; return [Platform::WIN32]; end
    
    def inherited subclass
      Cl.class.instance_eval{ def autoconfigurable; return false; end }
    end
    
  end
  
  def initialize(name, version, config = {})
    super(name)
    @version = version
    @vc_install_dir = get_directory config, 'VCInstallDir'
    @vs_install_dir = get_directory config, 'VSInstallDir'
    @vc_common_tools_dir = get_directory config, 'VCCommonToolsDir'
    @windows_sdk_dir = get_directory config, 'WindowsSdkDir'
  end
  
  def autoconfigure
    super
    configure_directory :@vc_install_dir, 'VCInstallDir', lambda { get_vc_install_dir }
    configure_directory :@vs_install_dir, 'VSInstallDir', lambda { get_vs_install_dir }
    configure_directory :@vc_common_tools_dir, 'VCCommonToolsDir', lambda { get_vs_common_tools_dir }
    configure_directory :@windows_sdk_dir, 'WindowsSdkDir', lambda { get_windows_sdk_dir }
  end
  
  def reg_query path, name
    Win32::Registry::HKEY_LOCAL_MACHINE.open(path) do |reg|
      type, data = reg.read(name)
      return data
    end
    abort('No value for reg query ' << path << " /v " << name)
  end
  
  def get_vs_install_dir
    return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VS7', @version)
  end
  
  def get_vc_install_dir
    return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VC7', @version)
  end
  
  def load_env
    # Microsoft Visual Studio
    path = @vs_install_dir.join('Common7', 'IDE').to_s
    # Microsoft Visual Studio Common Tools
    path << ';' << @vs_common_tools_dir.to_s
    # Microsoft Visual Compiler
    path << ';' << @vc_install_dir.join('BIN').to_s
    # We may add VCPackages to path
    ENV['INCLUDE'] = @vc_install_dir.join('INCLUDE').to_s
    ENV['LIB'] = @vc_install_dir.join('LIB').to_s
    ENV['LIBPATH'] = @vc_install_dir.join('LIB').to_s
    # Microsoft SDK
    path << ";" << @windows_sdk_dir.join('bin').to_s
    ENV['INCLUDE'] += ";" << @windows_sdk_dir.join('include').to_s
    ENV['LIB'] += ";" << @windows_sdk_dir.join('lib').to_s
    # Set new environment
    ENV['PATH'] = path << ";" << ENV['PATH']
  end
  
end
