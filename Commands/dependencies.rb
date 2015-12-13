module Jud
  def self.dependencies
    if ARGV.length > 0
      Application.dependencies $appname, ARGV.shift
    else
      Application.dependencies $appname
    end
  end
end
