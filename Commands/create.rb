module Jud
  def self.create
    repository = ARGV.shift
    name = ARGV.shift
    Platform.create repository, name
    Jud::Config.instance.config['main']['platform'] = name
  end
end
