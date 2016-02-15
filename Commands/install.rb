module Jud
  def self.install
    if ARGV.length > 0 then
      Application.install $appname, ARGV.shift
    else
      Application.install $appname
    end
    #options = {}
    #while ARGV.length > 0
    #  arg = ARGV.shift
    #  case arg[0]
    #  when '-'
    #    options[arg[1..-1].to_sym] = false
    #  when '+'
    #    options[arg[1..-1].to_sym] = true
    #  end
    #end
  end
end
