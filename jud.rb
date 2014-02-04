#!/usr/bin/env ruby -W0

require 'pathname'

$juddir = Pathname.new(__FILE__).realpath.dirname
$:.unshift $juddir.join('Library').to_s
$:.unshift $juddir.join('Platforms').to_s
$:.unshift $juddir.join('Tools').to_s

require 'config'
require 'platform'
require 'utilities'

at_exit { Jud::Config.instance.save }

$general_config = Jud::Config.instance.config['main']
$tools_config = Jud::Config.instance.config['tools']

require 'git'
require 'svn'

case ARGV.first
when 'download' then
  ARGV.shift
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
        puts Platform.green("#{url} looks like a Git repository")
        scm = klass.new(klass.name, url)
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
          scm = klass.new(klass.name, url)
          status = scm.checkout home, :safe => true
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
      config['scm'] = scm.class.name
      config['url'] = url
      config['dir'] = dir.to_s
      config['home'] = home.to_s
      exit
    end
  end
when 'create' then
  ARGV.shift
  repository = ARGV.shift
  name = ARGV.shift
  composites = []
  while ARGV.length > 0
    composites << ARGV.shift
  end
  Platform.create repository, name, composites
  Jud::Config.instance.config['main']['default'] = name
  exit
end

if not Jud::Config.instance.config['main'].include? 'default' then
  abort('Please, create a platform with jud create <repository> <platform>')
end

platform = $general_config['default']
$platform_config = Jud::Config.instance.config['platforms'][platform]

$platform = Platform.new platform
$platform.load_tools

$:.unshift $home.join('Applications').to_s

require 'application'
Dir.glob $home.join('Applications', '*.rb').to_s do |rb|
  load rb
end

require 'configuration'
Dir.glob $home.join('Configurations', '*.rb').to_s do |rb|
  load rb
end

case ARGV.first
when 'help', nil
  print 'jud' +
    ' [branch <app> <branch>]' +
    ' [build <conf>]' +
    ' [test <conf>]' +
    ' [install <app> [+<opt>]*[-<opt>]*]' +
    ' [option <path1> <pathn>* <value>' +
    ' [options <app>]' +
    ' [tag <app> <tag>]' +
    ' [tags <app>]' +
    "\n"
when 'branch'
  ARGV.shift
  app = Object.const_get(ARGV.shift).new
  app.scm_tool.branch app.src, ARGV.shift
when 'tag'
  ARGV.shift
  app = Object.const_get(ARGV.shift).new
  app.class.scm_tool.tag app.src, ARGV.shift
when 'tags'
  ARGV.shift
  app = Object.const_get(ARGV.shift).new
  app.class.scm_tool.tags app.src
when 'install'
  ARGV.shift
  name = ARGV.shift
  options = {}
  while ARGV.length > 0
    arg = ARGV.shift
    case arg[0]
    when '-'
      options[arg[1..-1].to_sym] = false
    when '+'
      options[arg[1..-1].to_sym] = true
    end
  end
  claz = Object.const_get(name)
  claz.new.install options
when 'options'
  ARGV.shift
  claz = Object.const_get(ARGV.shift)
  claz.build_tool.options.each do | key, option |
    puts key, "\t" + (option[1].nil? ? 'No description' : option[1])
  end
when 'option'
  ARGV.shift
  h = Jud::Config.instance.config
  paths = ARGV.shift.split('.')
  paths[0..-2].each { |p| h = h[p] }
  h[paths.last] = ARGV.shift
when 'build'
  ARGV.shift
  conf = Object.const_get(ARGV.shift).new
  conf.build
when 'submit'
  ARGV.shift
  conf = Object.const_get(ARGV.shift).new
  conf.submit
when 'pack'
  ARGV.shift
  app = Object.const_get(ARGV.shift).new
  app.pack
when 'update'
  ARGV.shift
  scm.update $home
end
