require 'java'

class Javac < Jud::Java::Compiler
  
  class << self
    
    def extra_configure config
      unless Platform.is_windows? then
        ENV['JAVA_HOME'] = Pathname.new(@path).dirname.dirname.to_s
        #ENV['LD_LIBRARY_PATH'] = '' unless ENV.has_key? 'LD_LIBRARY_PATH'
        #ENV['LD_LIBRARY_PATH'] = "#{ENV['JAVA_HOME']}/jre/lib/i386:#{ENV['JAVA_HOME']}/jre/lib/i386/client:" << ENV['LD_LIBRARY_PATH']
      end
    end
    
  end
  
  Javac.configure
  
  def initialize config = {}
    super()
  end
  
end
