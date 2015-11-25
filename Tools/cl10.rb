require 'Tools/cl'

module Jud::Tools
  class Cl10 < Cl
    
    class << self
      
      def configure
        # Nothing to configure. Everything is done by the class Cl.
      end
      
      def initialize_from_registry toolname, registry, version
        super toolname, registry, version
        # Windows SDK
        reg_name = registry + '\Microsoft\Microsoft SDKs\Windows\v7.0A' # v7.0A
        windows_sdk_dir = reg_query reg_name, 'InstallationFolder'
        save_config_property toolname, 'WindowsSdkDir', windows_sdk_dir
        # NMake
        config = get_configuration toolname        
        old_path = ENV['PATH']
        path = config['VCInstallDir'] + '\\' + 'bin'
        ENV['PATH'] = path + ';' + old_path
        Jud::Tools::NMake.configure "NMake #{version.major} (32)", 'nmake'
        path = config['VCInstallDir'] + '/bin/amd64'
        ENV['PATH'] = path + ';' + old_path
        Jud::Tools::NMake.configure "NMake #{version.major} (64)", 'nmake'
        ENV['PATH'] = old_path
      end
      
    end
    
    def initialize config={}
      super '10.0', config
    end
        
    def setenv context
      
      super context
      
      # Microsoft Visual Compiler
      context.setenv 'INCLUDE', @vc_install_dir + 'INCLUDE'
      context.setenv 'LIB', @vc_install_dir + 'lib' if context.arch =~ /x86/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'amd64' if context.arch =~ /x64/
      context.setenv 'LIBPATH', @vc_install_dir + 'lib' if context.arch =~ /x86/
      context.setenv 'LIBPATH', @vc_install_dir + 'lib' + 'amd64' if context.arch =~ /x64/
      context.appenv 'PATH', @vc_install_dir + 'bin' if context.arch =~ /x86/
      context.appenv 'PATH', @vc_install_dir + 'bin' + 'amd64' if context.arch =~ /x64/
      
      # Windows SDK
      context.appenv 'INCLUDE', @windows_sdk_dir + 'include'
      context.appenv 'LIB', @windows_sdk_dir + 'lib' if context.arch =~ /x86/
      context.appenv 'LIB', @windows_sdk_dir + 'lib' + 'x64' if context.arch =~ /x64/
      context.appenv 'PATH', @windows_sdk_dir + 'bin' if context.arch =~ /x86/
      context.appenv 'PATH', @windows_sdk_dir + 'bin' + 'x64' if context.arch =~ /x64/
      
    end
    
  end
end
