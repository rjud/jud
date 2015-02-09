require 'c'
require 'win32_utilities'

class Cl < Jud::C::Compiler
  
  class << self
    
    attr_reader :vc_install_dir, :vs_install_dir, :vc_common_tools_dir
    attr_reader :framework_dir, :windows_sdk_dir
    
    def load_path; false; end
    
    def variants; return [Platform::WIN32]; end
    
    def extra_configure config
      # Configure
      configure_directory config, 'VCInstallDir', lambda { get_vc_install_dir }
      configure_directory config, 'VSInstallDir', lambda { get_vs_install_dir }
      configure_directory config, 'VSCommonToolsDir', lambda { get_vs_common_tools_dir }
      configure_directory config, 'WindowsSdkDir', lambda { get_windows_sdk_dir }
      configure_directory config, 'FrameworkDir', lambda { get_framework_dir }
      configure_directory config, 'AdditionalDllDir', lambda { get_additional_dll_dir }
      # Get the final configuration
      @vc_install_dir = get_directory config, 'VCInstallDir'
      @vs_install_dir = get_directory config, 'VSInstallDir'
      @vs_common_tools_dir = get_directory config, 'VSCommonToolsDir'
      @windows_sdk_dir = get_directory config, 'WindowsSdkDir'
      @framework_dir = get_directory config, 'FrameworkDir'
      @additional_dll_dir = get_directory config, 'AdditionalDllDir'
      # Load environment
      # Microsoft Visual Studio
      path = File.join(@vs_install_dir, 'Common7', 'IDE')
      # Microsoft Visual Studio Common Tools
      path << ';' << @vs_common_tools_dir
      # Microsoft Visual Compiler
      path << ';' << File.join(@vc_install_dir, 'BIN')
      # MSPDB DLLs (for CMake 3)
      path << ';' << @additional_dll_dir
      # We may add VCPackages to path
      ENV['INCLUDE'] = File.join(@vc_install_dir, 'INCLUDE')
      ENV['LIB'] = File.join(@vc_install_dir, 'LIB')
      ENV['LIBPATH'] = File.join(@vc_install_dir, 'LIB')
      # Microsoft SDK
      if @windows_sdk_dir then
        path << ";" << File.join(@windows_sdk_dir, 'bin')
        path << ";" << File.join(@windows_sdk_dir, 'bin', 'x86') # WIN7 + MSVC11
        ENV['INCLUDE'] += ";" << File.join(@windows_sdk_dir, 'include')
        ENV['INCLUDE'] += ";" << File.join(@windows_sdk_dir, 'include', 'shared') # WIN7 + MSVC11
        ENV['INCLUDE'] += ";" << File.join(@windows_sdk_dir, 'include', 'winrt') # WIN7 + MSVC11
        ENV['INCLUDE'] += ";" << File.join(@windows_sdk_dir, 'include', 'um') # WIN7 + MSVC11
        ENV['LIB'] += ";" << File.join(@windows_sdk_dir, 'lib')
        ENV['LIB'] += ";" << File.join(@windows_sdk_dir, 'lib', 'win8', 'um', 'x86') # WIN7 + MSVC11
      end
      # Framework .NET (to have msbuild)
      path << ";" << @framework_dir
      # Set new environment
      ENV['PATH'] = path << ";" << ENV['PATH']
    end
    
    def get_vs_install_dir
	  begin
        return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VS7', version)
      rescue Win32::Registry::Error
	    return Pathname.new reg_query('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VS7', version)
	  end
	end
    
    def get_vc_install_dir
	  begin
        return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VC7', version)
      rescue Win32::Registry::Error
	    return Pathname.new reg_query('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7', version)
	  end
    end
    
    def get_additional_dll_dir # Only for CMake
      return Pathname.new reg_query('SOFTWARE\Wow6432Node\Microsoft\AppEnv\\' + version, 'AdditionalDllsFolder')
    end
    
  end
  
  def initialize config = {}
    super()
  end
  
end
