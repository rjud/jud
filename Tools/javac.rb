require 'java'

module Jud::Tools
  class Javac < Jud::Compiler
    
    include Jud::Languages::Java
    
    class << self
      
      def configure
        #ENV['JAVA_HOME'] = Pathname.new(@path).dirname.dirname.to_s
        #ENV['LD_LIBRARY_PATH'] = '' unless ENV.has_key? 'LD_LIBRARY_PATH'
        #ENV['LD_LIBRARY_PATH'] = "#{ENV['JAVA_HOME']}/jre/lib/i386:#{ENV['JAVA_HOME']}/jre/lib/i386/client:" << ENV['LD_LIBRARY_PATH']
      end
    
    end
    
    def initialize config={}
      super config
    end
    
  end
end
