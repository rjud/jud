require 'compiler'
require 'c'
require 'cxx'
require 'version'
require 'win32_utilities'

class Cl < Jud::Compiler
  
  include Jud::Languages::C
  include Jud::Languages::Cxx
  
  class << self
    
    def configure
      [ 'SOFTWARE', 'SOFTWARE\Wow6432' ].each do |registry|
        begin
          vcpath = registry + '\Microsoft\VisualStudio\SxS\VC7' 
          begin
            Win32::Registry::HKEY_LOCAL_MACHINE.open(vcpath) do |reg|
              puts "Read registry entry #{vcpath}"
              reg.each_value do |name, _, data|
                if /^\d+.\d+$/ =~ name
                  version = Jud::Version.new name
                  Platform.putfinds "Cl#{version.major}", data
                  require "cl#{version.major}"
                  ['x86', 'x64'].each do |arch|
                    tool = Object.const_get("Jud::Tools::Cl#{version.major}")
                    tool.initialize_from_registry "Cl#{version.major} (#{arch})", registry, version, arch
                  end
                end
              end
            end
          rescue Encoding::UndefinedConversionError => e
            puts "Undefined conversion error while reading registry:\n  #{e}"
          end
        rescue Win32::Registry::Error => e
          puts "Skip registry entry #{vcpath}:\n  #{e.message}"
        end
      end
    end
    
    def initialize_from_registry toolname, registry, version, arch
      # Visual Compiler
      reg_name = registry + '\Microsoft\VisualStudio\SxS\VC7'
      vc_install_dir = Pathname.new reg_query reg_name, version.to_s
      # Visual Studio tools
      reg_name = registry + '\Microsoft\VisualStudio\SxS\VS7'
      vs_install_dir = Pathname.new reg_query reg_name, version.to_s
      # Additional DLLs
      reg_name = registry + "\\Microsoft\\AppEnv\\#{version.to_s}"
      additional_dll_dir = Pathname.new reg_query reg_name, 'AdditionalDllsFolder'
      # VS Common tools
      comntools = "VS#{version.major}#{version.minor}COMNTOOLS"
      vs_common_tools_dir =
        if ENV.key? comntools then
          ENV[comntools]
        else
          vs_install_dir.join 'Common7', 'Tools'
        end
      # Framework
      reg_name = registry + '\Microsoft\VisualStudio\SxS\VC7'
      dir = reg_query reg_name, arch == 'x86' ? 'FrameworkDir32' : 'FrameworkDir64'
      ver = reg_query reg_name, arch == 'x86' ? 'FrameworkVer32' : 'FrameworkVer64'
      framework_dir = File.join dir, ver        
      # Save in the config file
      save_config_property toolname, 'VCInstallDir', vc_install_dir
      save_config_property toolname, 'VSInstallDir', vs_install_dir
      save_config_property toolname, 'VSCommonToolsDir', vs_common_tools_dir
      save_config_property toolname, 'FrameworkDir', framework_dir
      save_config_property toolname, 'AdditionalDllDir', additional_dll_dir
      # NMake
      old_path = ENV['PATH']
      ENV['PATH'] = (vc_install_dir + 'bin').to_s + ';' + ENV['PATH']
      Jud::Tools::NMake.configure "NMake#{version.major}", 'nmake'
      ENV['PATH'] = old_path
    end
    
    def variants; return [Platform::WIN32]; end
    
  end
  
  attr_reader :vc_install_dir, :vs_install_dir, :vc_common_tools_dir
  attr_reader :additional_dll_dir, :framework_dir, :windows_sdk_dir
  attr_reader :version
  
  def initialize options={}
    super options
    @vc_install_dir = Pathname.new @config['VCInstallDir']
    @vs_install_dir = Pathname.new @config['VSInstallDir']
    @vs_common_tools_dir = Pathname.new @config['VSCommonToolsDir']
    @additional_dll_dir = Pathname.new @config['AdditionalDllDir']
    @framework_dir = Pathname.new @config['FrameworkDir']
    @windows_sdk_dir = Pathname.new @config['WindowsSdkDir']
  end
  
  def setenv context
    
    # Setting PATH
    
    # Microsoft Visual Studio Tools        
    context.appenv 'PATH', @vs_install_dir + 'Common7' + 'IDE'
    # Microsoft Visual Studio Common Tools
    context.appenv 'PATH', @vs_common_tools_dir
    # Microsoft Visual Compiler
    context.appenv 'PATH', @vc_install_dir + 'BIN'
    # MSPDB DLLs (for CMake 3)
    context.appenv 'PATH', @additional_dll_dir
    # Framework .NET (to have msbuild)
    context.appenv 'PATH', @framework_dir
    # Microsoft SDK
    if @windows_sdk_dir
      context.appenv 'PATH', @windows_sdk_dir + 'bin'
      context.appenv 'PATH', @windows_sdk_dir + 'bin' + 'x86' # WIN7 + MSVC11
    end
    
    # Setting INCLUDE
    context.setenv 'INCLUDE', @vc_install_dir + 'INCLUDE'
    context.appenv 'INCLUDE', @windows_sdk_dir + 'include'
    context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'shared' # WIN7 + MSVC11
    context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'winrt'  # WIN7 + MSVC11
    context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'um'     # WIN7 + MSVC11
    
    # Setting LIB
    context.setenv 'LIB', @vc_install_dir + 'LIB'
    if @windows_sdk_dir
      context.appenv 'LIB', @windows_sdk_dir + 'lib'
      context.appenv 'LIB', @windows_sdk_dir + 'lib' + 'win8' + 'um' + 'x86'    # WIN7 + MSVC11 (JBE)
      context.appenv 'LIB', @windows_sdk_dir + 'lib' + 'winv6.3' + 'um' + 'x86' # WIN7 + MSVC12 (LBA)
    end
    
    # Setting LIBPATH
    context.setenv 'LIBPATH', @vc_install_dir + 'LIB'
    
  end
  
end
