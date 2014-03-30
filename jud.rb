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
      if klass.configured? and klass.guess url then
        puts Platform.green("#{url} looks like a Git repository")
        scm = klass.new url
        status = scm.checkout home, nil
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
          if klass.configured? then
            puts (Platform.green "Try to download with #{klass.name}")
            scm = klass.new url
            status = scm.checkout home, nil, :safe => true
            throw :download_ok if status[0].success?
          end
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
  Platform.create repository, name
  Jud::Config.instance.config['main']['default'] = name
  exit
end

begin
  
  if not Jud::Config.instance.config['main'].include? 'default' then
    abort('Please, create a platform with jud create <repository> <platform>')
  end
  
  platform = $general_config['default']
  $platform_config = Jud::Config.instance.config['platforms'][platform]
  
  $platform = Platform.new platform
  $platform.load_composites
  $platform.load_tools
  
  repository = $platform_config['repository']
  $repository_config = $general_config['repositories'][repository]
  
  scm = $repository_config['scm']
  url = $repository_config['url']
  scm = Object.const_get(scm).new url
  
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
  when 'enable'
    ARGV.shift
    $platform.setup ARGV.shift
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
  when 'optionset'
    ARGV.shift
    h = Jud::Config.instance.config
    paths = ARGV.shift.split('.')
    paths[0..-2].each { |p| h = h[p] }
    h[paths.last] = ARGV.shift
  when 'optionadd'
    ARGV.shift
    h = Jud::Config.instance.config
    paths = ARGV.shift.split('.')
    paths[0..-2].each { |p| h = h[p] }
    h[paths.last] = [] if not h.include? paths.last
    h[paths.last] << ARGV.shift
  when 'configurations'
    puts 'Available configurations'
    subsubclasses(Configuration).each do |c|
      puts "  #{c}"
    end
  when 'build'
    ARGV.shift
    conf = Object.const_get(ARGV.shift).new
    if ARGV.length > 0 then
      conf.build ARGV.shift
    else
      conf.build
    end
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
    if ARGV.length > 0 then
      conf = Object.const_get(ARGV.shift).new
      conf.update
    end
  end
  
rescue Platform::Error, Tool::Error => e
  puts (Platform.red e)
end
