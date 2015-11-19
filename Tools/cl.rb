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
      [ 'SOFTWARE', 'SOFTWARE\Wow6432Node' ].each do |registry|
        vcpath = registry + '\Microsoft\VisualStudio\SxS\VC7' 
        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open(vcpath) do |reg|
            puts "Read registry entry #{vcpath}"
            reg.each_value do |name, _, data|
              if /^\d+.\d+$/ =~ name
                version = Jud::Version.new name
                Platform.putfinds "Cl#{version.major}", data
				begin
				  require "cl#{version.major}"
                  tool = Object.const_get("Jud::Tools::Cl#{version.major}")
				  tool.initialize_from_registry "Cl#{version.major}", registry, version
				rescue LoadError => e
				  puts (Platform.red "Skip Cl#{version.major}")
				end
              end
            end
          end
		rescue Jud::Library::RegistryError, Win32::Registry::Error => e
		  puts (Platform.red "Skip registry entry #{vcpath}:\n  #{e.message}")
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
      begin
        reg_name = registry + "\\Microsoft\\AppEnv\\#{version.to_s}"
        additional_dll_dir = Pathname.new reg_query reg_name, 'AdditionalDllsFolder'
      rescue
        puts (Platform.red "Can't read registry key #{reg_name}")
      end
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
  attr_reader :windows_sdk_dir
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
  end
  
  def setenv context
    # Microsoft Visual Studio Tools        
    context.appenv 'PATH', @vs_install_dir + 'Common7' + 'IDE'
    # Microsoft Visual Studio Common Tools
    context.appenv 'PATH', @vs_common_tools_dir
    # MSPDB DLLs (for CMake 3)
    context.appenv 'PATH', @additional_dll_dir
    # Framework .NET (to have msbuild)
    context.appenv 'PATH', @framework_dir32 if context.arch =~ /x86/
    context.appenv 'PATH', @framework_dir64 if context.arch =~ /x64/    
    # Setting Platform
    context.setenv 'Platform', 'X64' if context.arch =~ /x64/
  end
  
end
