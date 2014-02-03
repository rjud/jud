require 'compiler'
require 'win32/registry'

class Cl < Compiler
  
  class << self
    
    def name; return "cl"; end
    def autoconfigurable; return true; end
    
    def autoconfigure
      name, major = self.autoconfigure2
      if name then
        cl = Cl.new name
        autoconfigure_directory 'VCInstallDir', cl.get_vc_install_dir.to_s
        autoconfigure_directory 'VSInstallDir', cl.get_vs_install_dir.to_s
        #autoconfigure_directory 'VCCommonToolsDir', cl.get_vs_common_tools_dir.to_s
      end
    end
    
    def autoconfigure2
      path = 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7'
      Win32::Registry::HKEY_LOCAL_MACHINE.open(path) do |reg|
        reg.each_value do |name, type, data|
          if /^(?<major>\d+)\.\d+/ =~ name then
            puts (Platform.green "Found C++ compiler msvc#{major}")
            return name, major
          end
        end
      end
    end
    
    def variants; return [Platform::WIN32]; end
    
    def inherited subclass
      Cl.class.instance_eval{ def autoconfigurable; return false; end }
    end
    
  end
  
  def initialize(version)
    @version = version
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
    path = get_vs_install_dir.join('Common7', 'IDE').to_s
    # Microsoft Visual Studio Common Tools
    path << ';' << get_vs_common_tools_dir.to_s
    # Microsoft Visual Compiler
    vc_install_dir = get_vc_install_dir
    path << ';' << vc_install_dir.join('BIN').to_s
    # We may add VCPackages to path
    ENV['INCLUDE'] = vc_install_dir.join('INCLUDE').to_s
    ENV['LIB'] = vc_install_dir.join('LIB').to_s
    ENV['LIBPATH'] = vc_install_dir.join('LIB').to_s
    # Microsoft SDK
    sdk_install_dir = get_windows_sdk_dir
    path << ";" << sdk_install_dir.join('bin').to_s
    ENV['INCLUDE'] += ";" << sdk_install_dir.join('include').to_s
    ENV['LIB'] += ";" << sdk_install_dir.join('lib').to_s
    # Set new environment
    ENV['PATH'] = path << ";" << ENV['PATH']
  end
  
end
