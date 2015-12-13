module Jud
  def self.ocra
    puts "I am loading all requirements for ocra."
    puts "If you want some help, `jud help` could be useful for you."
    Dir.glob ($juddir + 'Library' + '*.rb').to_s do |rb|
      puts "Load #{rb}"
      require (File.basename rb)
    end
    Dir.glob ($juddir + 'Platforms' + '*.rb').to_s do |rb|
      puts "Load #{rb}"
      require ('Platforms/' + (File.basename rb) )
    end
    Dir.glob ($juddir + 'Tools' + '*.rb').to_s do |rb|
      puts "Load #{rb}"
      require ('Tools/' + (File.basename rb) )
    end
    Dir.glob ($juddir + 'Projects' + '*.rb').to_s do |rb|
      puts "Load #{rb}"
      require (File.basename rb)
    end
    Dir.glob ($juddir + 'Applications' + '*.rb').to_s do |rb|
      puts "Load #{rb}"
      require (File.basename rb)
    end
    case RbConfig::CONFIG['host_os']
    when /mswin|mingw/
      puts "Load win32ole"
      require 'win32ole'
    end
    puts "Load http/cookie_jar"
    require 'http/cookie_jar/abstract_store'
    require 'http/cookie_jar/hash_store'
    puts "Load net/ftp"
    require 'net/ftp'
    puts "Load zip"
    require 'zip'
  end
end
