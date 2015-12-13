module Jud
  def self.upload
    project = ARGV.shift
    Application.upload appname, project
  end
end
