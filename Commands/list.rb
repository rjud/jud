module Jud
  def self.list
    $do_nothing = true
    case ARGV.shift
    when 'applications'
      Dir.glob ($juddir + 'Applications' + '*.rb').to_s do |rb|
        load rb
      end
      Dir.glob ($home + 'Applications' + '*.rb').to_s do |rb|
        load rb
      end
      $applications.each do |app|
        puts "  #{app}"
      end
    when 'platforms'
      Jud::Config.instance.config['platforms'].each do |name, _|
        puts "  #{name}"
      end
    when 'repositories'
      Jud::Config.instance.config['main']['repositories'].each do |name, config|
        puts "  #{name}: #{config['url']}"
      end
    when 'tools'
      tools = {}
      Jud::Config.instance.config['tools'].each do |name, config|
        tools[config['instanceof']] = []
      end
      Jud::Config.instance.config['tools'].each do |name, config|
        tools[config['instanceof']] << name
      end
      tools.each do |classname, instances|
        puts "  #{classname}"
        instances.each do |instance|
          puts "  |--#{instance}"
        end
      end
    end
  end
end
