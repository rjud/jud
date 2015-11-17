require 'cl'

module Jud::Tools
  class Cl14 < Cl
    
    class << self
      
      def configure
        # Nothing to configure. Everything is done by the class Cl.
      end  
      
      def initialize_from_registry toolname, registry, version
        super toolname, registry, version
        # Windows SDK
        reg_name = registry + '\Microsoft\Microsoft SDKs\Windows\v10.0'
        windows_sdk_dir = reg_query reg_name, 'InstallationFolder'
        save_config_property toolname, 'WindowsSdkDir', windows_sdk_dir
        windows_sdk_ver = reg_query reg_name, 'ProductVersion'
        dirs = Dir.glob (File.join windows_sdk_dir.gsub('\\', '/'), 'Lib', "#{windows_sdk_ver}*") 
        save_config_property toolname, 'WindowsSdkVer', (File.basename dirs[0])
      end
      
    end
    
    attr_reader :windows_sdk_ver
    
    def initialize config={}
      super config
      @windows_sdk_ver = Pathname.new @config['WindowsSdkVer']
    end
    
    def setenv context
      
      # Setting PATH
      context.appenv 'PATH', @vc_install_dir + 'BIN' if context.arch =~ /x86/
      context.appenv 'PATH', @vc_install_dir + 'BIN' + 'amd64' if context.arch =~ /x64/
      context.appenv 'PATH', @windows_sdk_dir + 'bin' + context.arch
      
      # Setting INCLUDE
      windows_sdk_include_dir = @windows_sdk_dir + 'include' + @windows_sdk_ver
      context.appenv 'INCLUDE', windows_sdk_include_dir + 'shared'
      context.appenv 'INCLUDE', windows_sdk_include_dir + 'ucrt'
      context.appenv 'INCLUDE', windows_sdk_include_dir + 'um'
      
      # Setting LIB
      context.setenv 'LIB', @vc_install_dir + 'lib' if context.arch =~ /x86/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'amd64' if context.arch =~ /x64/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'arm' if context.arch =~ /arm/
      
      context.appenv 'LIB', @windows_sdk_dir + 'lib' + @windows_sdk_ver + 'um' + context.arch
      context.appenv 'LIB', @windows_sdk_dir + 'lib' + @windows_sdk_ver + 'ucrt' + context.arch
      
      # Setting LIBPATH
      context.setenv 'LIBPATH', @vc_install_dir + 'LIB' if context.arch =~ /x86/
      context.setenv 'LIBPATH', @vc_install_dir + 'LIB' + 'amd64' if context.arch =~ /x64/
      context.setenv 'LIB', @vc_install_dir + 'lib' + 'arm' if context.arch =~ /arm/
      
    end
    
  end
end
