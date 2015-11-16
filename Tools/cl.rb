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
                  tool = Object.const_get("Jud::Tools::Cl#{version.major}")
                  tool.initialize_from_registry "Cl#{version.major}", registry, version
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
    
    def initialize_from_registry toolname, registry, version
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
      dir32 = reg_query reg_name, "FrameworkDir32"
      ver32 = reg_query reg_name, "FrameworkVer32"
      dir64 = reg_query reg_name, "FrameworkDir64"
      ver64 = reg_query reg_name, "FrameworkVer64"
      framework_dir32 = File.join dir32, ver32
      framework_dir64 = File.join dir64, ver64
      # Save in the config file
      save_config_property toolname, 'VCInstallDir', vc_install_dir
      save_config_property toolname, 'VSInstallDir', vs_install_dir
      save_config_property toolname, 'VSCommonToolsDir', vs_common_tools_dir
      save_config_property toolname, 'FrameworkDir32', framework_dir32
      save_config_property toolname, 'FrameworkDir64', framework_dir64
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
  attr_reader :additional_dll_dir, :framework_dir32, :framework_dir64
  attr_reader :windows_sdk_dir, :windows_sdk_ver
  attr_reader :version
  
  def initialize options={}
    super options
    @vc_install_dir = Pathname.new @config['VCInstallDir']
    @vs_install_dir = Pathname.new @config['VSInstallDir']
    @vs_common_tools_dir = Pathname.new @config['VSCommonToolsDir']
    @additional_dll_dir = Pathname.new @config['AdditionalDllDir']
    @framework_dir32 = Pathname.new @config['FrameworkDir32']
    @framework_dir64 = Pathname.new @config['FrameworkDir64']
    @windows_sdk_dir = Pathname.new @config['WindowsSdkDir']
    @windows_sdk_ver = Pathname.new @config['WindowsSdkVer']
  end
  
  def setenv context
    
    # Setting PATH
    
    # Microsoft Visual Studio Tools        
    context.appenv 'PATH', @vs_install_dir + 'Common7' + 'IDE'
    # Microsoft Visual Studio Common Tools
    context.appenv 'PATH', @vs_common_tools_dir
    # Microsoft Visual Compiler
    if context.arch =~ /x64/
      # Keep it before the following
      if not (@vc_install_dir + 'BIN' + 'x86_amd64' + 'nmake.exe').exist? or not (@vc_install_dir + 'BIN' + 'amd64' + 'nmake.exe').exist?
        context.appenv 'PATH', @vc_install_dir + 'BIN'
      end
      if (@vc_install_dir + 'BIN' + 'x86_amd64' + 'cl.exe').exist?
        context.appenv 'PATH', @vc_install_dir + 'BIN' + 'x86_amd64'
      elsif (@vc_install_dir + 'BIN' + 'amd64' + 'cl.exe').exist?
        context.appenv 'PATH', @vc_install_dir + 'BIN' + 'amd64'
      end
    else
      context.appenv 'PATH', @vc_install_dir + 'BIN'
    end
    # MSPDB DLLs (for CMake 3)
    context.appenv 'PATH', @additional_dll_dir
    # Framework .NET (to have msbuild)
    context.appenv 'PATH', @framework_dir32 if context.arch =~ /x86/
    context.appenv 'PATH', @framework_dir64 if context.arch =~ /x64/
    # Microsoft SDK
    if @windows_sdk_dir
      context.appenv 'PATH', @windows_sdk_dir + 'bin'
      context.appenv 'PATH', @windows_sdk_dir + 'bin' + context.arch
    end
    
    # Setting INCLUDE
    context.setenv 'INCLUDE', @vc_install_dir + 'INCLUDE'
    #context.appenv 'INCLUDE', @windows_sdk_dir + 'include'
    #context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'winrt'
    windows_sdk_include_dir = @windows_sdk_dir + 'include' + @windows_sdk_ver
    if not windows_sdk_include_dir.directory?
      windows_sdk_include_dir = @windows_sdk_dir + 'include'
    end
    context.appenv 'INCLUDE', windows_sdk_include_dir + 'shared'
    context.appenv 'INCLUDE', windows_sdk_include_dir + 'ucrt'
    context.appenv 'INCLUDE', windows_sdk_include_dir + 'um'
    
    # Setting LIB
    if context.arch =~ /x86/
      context.setenv 'LIB', @vc_install_dir + 'lib'
    elsif context.arch =~ /x64/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'amd64'
    elsif context.arch =~ /arm/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'arm'
    end
    if @windows_sdk_dir
      if (@windows_sdk_dir + 'lib' + @windows_sdk_ver + 'um').exist?
        context.appenv 'LIB', @windows_sdk_dir + 'lib' + @windows_sdk_ver + 'um' + context.arch
        if (@windows_sdk_dir + 'lib' + @windows_sdk_ver + 'ucrt').exist?
          context.appenv 'LIB', @windows_sdk_dir + 'lib' + @windows_sdk_ver + 'ucrt' + context.arch
        end
      else
        context.appenv 'LIB', @windows_sdk_dir + 'lib'        
      end
    end
    
    # Setting LIBPATH
    context.setenv 'LIBPATH', @vc_install_dir + 'LIB' if context.arch =~ /x86/
    context.setenv 'LIBPATH', @vc_install_dir + 'LIB' + 'amd64' if context.arch =~ /x64/

    # Setting Platform
    context.setenv 'Platform', 'X64' if context.arch =~ /x64/
    #context.setenv 'PreferredToolArchitecture', 'x64' if context.arch =~ /x64/
    #context.setenv 'CommandPromptType', 'Cross'
    #context.setenv 'FrameworkDIR64', 'C:\\windows\\Microsoft.NET\\Framework64'
    #context.setenv 'FrameworkVersion64', 'v4.0.30319'
    #context.setenv 'LIBPATH', "C:\\windows\\Microsoft.NET\\Framework64\\v4.0.30319;C:\\windows\\Microsoft.NET\\Framework64\\v3.5;C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319;C:\\windows\\Microsoft.NET\\Framework\v3.5;C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\VC\\LIB\\amd64;C:\\Program Files (x86)\\Windows Kits\\8.0\\References\\CommonConfiguration\\Neutral;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v8.0\\ExtensionSDKs\\Microsoft.VCLibs\\11.0\\References\\CommonConfiguration\\neutral"
    #context.setenv 'PATH', "C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\Common7\\IDE\\;C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\VC\\BIN\\x86_amd64;C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\VC\\BIN;C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\Common7\\Tools;C:\\Program Files (x86)\\Microsoft Visual Studio 11.0\\VC\\VCPackages;C:\\Program Files (x86)\\Windows Kits\\8.0\\bin\\x86;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v7.0A\\Bin\\"  







    
  end
  
end
