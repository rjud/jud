require 'build_tool'
require 'ant'
require 'antwrap'
require 'javac'
require 'rexml/document'

include REXML

class Array # Deprecated method redefined for antwrap
  def nitems()
    select{ |item| not item.nil? }.count
  end
end

class Eclipse < BuildTool
    
  def initialize
    super()
  end
  
  def load_projectfile
    projectfilename = @src.join('.project').to_s
    raise Error, "No .project in #{@src}" unless File.exists? projectfilename
    projectdoc = Document.new (File.new projectfilename)
    @ant.project.setName projectdoc.root.elements['name'][0].value
  end
  
  def load_classpath
    classpathfilename = "#{@src}/.classpath"
    msg = "No .classpath in #{@src}"
    raise Error, msg unless File.exists? classpathfilename
    classpathdoc = Document.new (File.new classpathfilename)
    classpathdoc.root.each_element('classpathentry') do |entry|
      case entry.attributes['kind']
      when 'src'
        @ant.project.setBasedir (to_path entry.attributes['path'])
      when 'lib'
        libname = entry.attributes['path'].value
        @ant.path(:id => (File.basename libname)) do |ant|
          ant.pathelement(:location => libname)
        end
      end
    end
  end
  
  def add_javac_task
    @javac_task = @ant.javac(:srcdir => @ant.basedir, :destdir => @classes)
    #do
    #  |ant|
    #  # ant.classpath(:refid => "common.class.path") 
    #end
    @jar_name = File.join(@build, @ant.name + '.jar')
    @jar_task = @ant.jar(:destfile => @jar_name, :basedir => @classes)
  end
  
  def to_path p
    if Pathname.new(p).absolute? then
      p
    else
      Pathname.new(@src).join(p).to_s
    end
  end
  
  def configure src, build, install, build_type, options={}
    @src = src
    @build = build
    @classes = File.join(build, 'classes')
    ant_home = Jud::Tools::Ant.new.ant_home
    ENV['CLASSPATH'] = ant_home.join('lib', 'ant.jar').to_s + ':' + ant_home.join('lib', 'ant-launcher.jar').to_s
    @ant = Antwrap::AntProject.new(:declarative => false) #, :loglevel => Logger::DEBUG)
    load_projectfile
    load_classpath
    add_javac_task
  end
  
  def build *args
    FileUtils.mkdir_p @classes unless File.directory? @classes
    @javac_task.execute
    @jar_task.execute
  end
  
  def install *args
    
  end
  
end
