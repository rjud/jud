require 'cl'

module Jud::Tools
  class Cl12 < Cl
    
    class << self
      
      def configure
        # Nothing to configure. Everything is done by the class Cl.
      end
      
      def initialize_from_registry toolname, registry, version
        super toolname, registry, version
        # Windows SDK
        reg_name = 'SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1'
        windows_sdk_dir = reg_query reg_name, 'InstallationFolder'
        save_config_property toolname, 'WindowsSdkDir', windows_sdk_dir
        save_config_property toolname, 'WindowsSdkVer', 'winv6.3'
      end
      
    end
    
    def initialize config={}
      super config
    end
    
  end
end
