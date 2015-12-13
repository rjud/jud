module Jud
  def self.build
    if ARGV.length > 0 then
      Application.build $appname, ARGV.shift
    else
      Application.build $appname
    end
  end
end
