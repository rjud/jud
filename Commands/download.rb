require 'Tools/git'
require 'Tools/svn'

module Jud
  def self.download
    url = ARGV.shift
    dir = Pathname.new(ARGV.shift)
    Dir.mkdir dir.to_s if not File.directory? dir.to_s
    dir = dir.realpath
    home = dir.join('home')
    status = nil
    scm = nil
    subsubclasses(SCMTool).each do |klass|
      begin
        if klass.guess url then
          puts Platform.green("#{url} looks like a #{Tool.toolname klass} repository")
          scm = klass.new url
          status = scm.checkout home
        end
      rescue Platform::Error => e
        puts (Platform.red e)
      end
    end
    catch :download_ok do
      if not status or not status[0].success? then
        puts (Platform.green "Can't guess the type of the repository #{url}")
        subsubclasses(SCMTool).each do |klass|
          begin
            puts (Platform.green "Try to download with #{klass.name}")
            scm = klass.new url
            status = scm.checkout home, nil
            throw :download_ok if status[0].success?
          rescue Platform::Error => e
            puts (Platform.red e)
          end
        end
        abort
      end
    end
    namefile = home.join 'NAME'
    File.open(namefile.to_s, "r") do |file|
      name = file.gets
      if name.empty? then
        puts "The file NAME is empty."
        abort
      else
        config = Jud::Config.instance.config['main']['repositories'][name]
        config['scm'] = Tool.toolname scm.class
        config['url'] = url
        config['dir'] = dir.to_s
        config['home'] = home.to_s
        exit
      end
    end
  end
end
