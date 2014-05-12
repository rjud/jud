require 'build_tool'
require 'antwrap'
require 'javac'
require 'rexml/document'

include REXML

class Eclipse < BuildTool
    
  def initialize
    super()
  end
  
  def load_projectfile
    projectfilename = @src.join('.project').to_s
    raise Error, "No .project in #{@src}" unless File.exists? projectfilename
    projectdoc = Document.new (File.new projectfilename)
    @antname = projectdoc.root.elements['name'][0]
  end
  
  def load_classpath
    classpathfilename = "#{@src}/.classpath"
    msg = "No .classpath in #{@src}"
    raise Error, msg unless File.exists? classpathfilename
    classpathdoc = Document.new (File.new classpathfilename)
    classpathdoc.root.each_element('classpathentry') do |entry|
      case entry.attributes['kind']
      when 'src'
        @ant.basedir = to_path entry.attributes['path']
      when 'lib'
        libname = entry.attributes['path']
        @ant.path(:id => (File.basename libname)) do |ant|
          ant.pathelement(:location => libname)
        end
      end
    end
  end
  
  def add_javac_task
    @javac_task = @ant.javac(:srcdir => @ant.basedir, :destdir => build) do
      |ant|
      # ant.classpath(:refid => "common.class.path") 
    end
  end
  
  def to_path p
    if File.absolute? p then
      p
    else
      File.join(src, p)
    end
  end
  
  def configure src, build, install, build_type, options={}
    @src = src
    @build = build
    load_projectfile
    @ant = Antwrap::AntProject.new(:declarative => false, :name => @antname)
    load_classpath
    add_javac_task
  end
  
  def build *args
    @javac_task.execute
  end
  
  def install *args
    
  end
  
end
