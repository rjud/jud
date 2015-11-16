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
    
    def initialize config={}
      super config
    end
    
  end
end
