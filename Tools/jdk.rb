require 'java'
require 'compiler'

module Jud::Tools
  class JDK < Jud::Compiler
    
    include Jud::Languages::Java
    
    class << self
      
      def configure
        if Platform.is_windows?          
          [ "SOFTWARE", "SOFTWARE\\Wow6432Node" ].each do |registry|
            begin
              reg_name = registry + "\\JavaSoft\\Java Development Kit"
              Win32::Registry::HKEY_LOCAL_MACHINE.open(reg_name) do |reg|
                reg.each_key do |key, _|
                  if key =~ /^\d+.\d+$/
                    home = Pathname.new reg_query (reg_name + "\\" + key), 'JavaHome'
                    path = home + 'bin' + 'java.exe'
                    tlname, arch =
                      if RUBY_PLATFORM =~ /i386/ or registry =~ /Wow6432Node/
                        ["JDK #{key} (32)", 'x86']
                      else
                        ["JDK #{key} (64)", 'x64']
                      end
                    save_config_property tlname, 'path', path
                    save_config_property tlname, 'version', key
                    save_config_property tlname, 'arch', arch
                    Platform.putfinds tlname, path
                  end
                end
              end
            rescue Win32::Registry::Error => e
              puts (Platform.red "Skip registry entry #{registry}\\JavaSoft\\Java Development Kit")
            end
          end
        else
          super
        end
      end
      
    end
    
    def initialize config={}
      super config
      @version = Jud::Version.new @config['version']
    end
    
    def build_name current_build_name, language
      "#{current_build_name}-jdk#{@version.minor}"
    end
    
    def setenv context
      context.appenv 'PATH', (Pathname.new @path).dirname
      context.setenv 'JAVA_HOME', (Pathname.new @path).dirname.dirname
    end
    
  end
end
