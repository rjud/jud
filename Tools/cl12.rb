if Platform.is_windows?
  
  require 'Tools/cl'
  
  module Jud::Tools
    class Cl12 < Cl
      
      class << self
	
	def configure
	  # Nothing to configure. Everything is done by the class Cl.
	end
	
	def initialize_from_registry toolname, registry, version
	  super toolname, registry, version
	  # Windows SDK
	  reg_name = registry + '\Microsoft\Microsoft SDKs\Windows\v8.1'
	  windows_sdk_dir = reg_query reg_name, 'InstallationFolder'
	  save_config_property toolname, 'WindowsSdkDir', windows_sdk_dir
	  save_config_property toolname, 'WindowsSdkVer', 'winv6.3'
	  # NMake
	  config = get_configuration toolname        
	  old_path = ENV['PATH']
	  path = config['VCInstallDir'] + '\\' + 'bin'
	  ENV['PATH'] = path + ';' + old_path
	  Jud::Tools::NMake.configure "NMake #{version.major}", 'nmake'
	  ENV['PATH'] = old_path
	end
	
      end
      
      attr_reader :windows_sdk_ver
      
      def initialize config={}
	super '12.0', config
	@windows_sdk_ver = Pathname.new @config['WindowsSdkVer']
      end
      
      def setenv context
	
	super context
	
	# Microsoft Visual Compiler
	context.setenv 'INCLUDE', @vc_install_dir + 'INCLUDE'
	context.setenv 'LIB', @vc_install_dir + 'lib' if context.arch =~ /x86/
	context.setenv 'LIB', @vc_install_dir + 'lib' + 'amd64' if context.arch =~ /x64/
	context.setenv 'LIBPATH', @vc_install_dir + 'lib' if context.arch =~ /x86/
	context.setenv 'LIBPATH', @vc_install_dir + 'lib' + 'amd64' if context.arch =~ /x64/
	context.appenv 'PATH', @vc_install_dir + 'BIN' # Always keep this line before the next line
	context.appenv 'PATH', @vc_install_dir + 'BIN' + 'x86_amd64' if context.arch =~ /x64/
	
	# Windows SDK
	context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'shared'
	context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'um'
	context.appenv 'INCLUDE', @windows_sdk_dir + 'include' + 'winrt'
	context.appenv 'LIB', @windows_sdk_dir + 'lib' + @windows_sdk_ver + 'um' + context.arch
	context.appenv 'PATH', @windows_sdk_dir + 'bin' + context.arch
	
      end
      
    end
  end
  
end
