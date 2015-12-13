module Jud
  def self.deploy
    if ARGV.length > 0
      Application.deploy appname, ARGV.shift
    else
      Application.deploy appname
    end
  end
end
