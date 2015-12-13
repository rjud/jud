module Jud
  def self.enable
    toolname = ARGV.shift
    exit if $platform_config['tools'].include? toolname
    if Jud::Config.instance.config['tools'].key? toolname
      $platform_config['tools'] << toolname
    else
      puts (Platform.red "I am sorry but I did not find a tool named #{toolname}.")
      puts (Platform.red "Could I suggest you to run `jud configure` or `jud list tools` ?")
    end
  end
end
