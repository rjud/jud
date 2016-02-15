module Jud
  def self.switch
    arg = ARGV.shift
    if arg == 'main'
      Jud::Config.instance.config['main']['application'] = 'main'
    elsif Jud::Config.instance.config['platforms'].key? arg
      Jud::Config.instance.config['main']['platform'] = arg
    else
      begin
        load $home.join('Applications', "#{arg.downcase}.rb").to_s
        Jud::Config.instance.config['main']['application'] = arg
        puts (Platform.green "Switch to application #{arg}")
      rescue LoadError => e
        puts (Platform.red "#{arg} is not a platform and I can't load an application with this name.")
        puts (Platform.red "")
        puts e
      end
    end
  end
end
