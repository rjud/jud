require 'config'

class Application
  
  attr_reader :name, :packdir
  
  def initialize
    @name = self.class.name
    @install = prefix
    @packdir = $packdir
  end
  
  def srcdir build_type
    $src.join(@name + (build_type ? '-' + build_type.to_s : '') )
  end
  
  def builddir build_type
    $build.join(@name + (build_type ? '-' + build_type.to_s : '') )
  end
  
  def prefix
    if Jud::Config.instance.config['applications']['separate_install_trees'] then
      prefix = $install.join(@name)
    else
      prefix = $install
    end
    prefix
  end
  
  def install_dependency claz
    depend = claz.new
    if depend.packfile.exist? then
      depend.unpack
    elsif depend.class.repository and depend.class.repository.exist? depend.packfile then
      depend.download
      depend.unpack
    else
      puts Platform.yellow('[' + name + "] install dependency " + depend.name)
      build_types.each do |bt|
        depend.checkout_this bt
        depend.configure_this bt
        depend.build_this bt
        depend.install_this bt
      end
      depend.pack_and_upload
      puts Platform.yellow('[' + name + "] dependency " + depend.name + " is installed")
    end
    depend.register_this
  end
  
  def install_dependencies options={}
    self.class.depends.each do |depend, cond|
      install = cond.nil? || options[cond]
      config = Jud::Config.instance.config['applications'][depend.name]
      install = (not config.has_key? 'prefix') if install
      install_dependency depend if install
    end
  end
  
  def checkout_this build_type
    src = srcdir build_type
    self.class.scm_tool.checkout src if not File.directory? src
  end
  
  def configure_this build_type, options={}
    src = srcdir build_type
    build = builddir build_type
    self.class.build_tool.configure src, build, @install, build_type, options    
  end
  
  def build_types
    [:Debug, :Release] + self.class.build_types
  end
  
  def build_this build_type
    self.class.build_tool.build (builddir build_type)
  end
  
  def install_this build_type
    self.class.build_tool.install (builddir build_type)
  end
  
  def register_this
    Jud::Config.instance.config['applications'][@name]['prefix'] = @install.to_s
  end
  
  def install options={}
    install_dependencies options
    build_types.each do |bt|
      checkout_this bt
      configure_this bt, options
      build_this bt
      install_this bt
    end
    pack_and_upload
    register_this
  end
  
  def submit options={}
    install_dependencies options
    self.class.submit_tool.build_tool = self.class.build_tool
    self.class.submit_tool.scm_tool = self.class.scm_tool
    status = SubmitTool::OK
    build_types.each do |bt|
      src = srcdir bt
      build = builddir bt
      self.class.scm_tool.checkout src if not File.directory? src
      s = self.class.submit_tool.submit src, build, @install, bt, options
      status = s if s > status
    end
    pack_and_upload if pack? status
    Jud::Config.instance.config['applications'][@name]['prefix'] = @install.to_s
  end
  
  def pack? status
    case status
    when SubmitTool::OK then true
    when SubmitTool::TESTS_NOK then true
    else false
    end
  end
  
  def packfilename
    self.name + '-' + RbConfig::CONFIG['host'] + '.' + self.class.pack_tool.ext
  end
  
  def packfile
    Pathname.new(@packdir).join(packfilename)
  end
  
  def pack_and_upload
    pack
    upload if self.class.repository
  end
  
  def pack
    puts Platform.blue('Pack ' + packfile.basename.to_s)
    self.class.pack_tool.pack packfile, @install
  end
  
  def unpack
    puts Platform.blue('Unpack ' + packfile.basename.to_s + ' to ' + @install.to_s)
    self.class.pack_tool.unpack packfile, @install
  end
  
  def download
    self.class.repository.download packfile
  end
  
  def upload
    self.class.repository.upload packfile
  end
  
  def depends options={}
    depends = []
    self.class.depends.each do |depend, cond|
      depends << depend if cond.nil? or options[cond.to_sym]
    end
    depends
  end
    
  class << self
    
    attr_reader :scm_tool, :build_tool, :submit_tool, :repository
    
    def pack_tool
      @pack_tool ? @pack_tool : ZipTool.new
    end
    
    def build_types
      @build_types ||= []
    end
    
    def depends
      @depends ||= []
    end
    
    def depend_on name, cond=nil
      depends << [name, cond]
    end
    
    def add_build_type name
      @build_types << name
    end
    
    def cmake &block
      @build_tool= CMake.new
      @build_tool.instance_eval &block if block_given? &block
    end
    
    def ctest &block
      @submit_tool = CTest.new
      @submit_tool.instance_eval &block if block_given? &block
    end
    
    def git url
      @scm_tool = Git.new url
    end
    
    def redmine url, projectid
      @repository = Redmine.new url, projectid
    end
    
    def svn url
      @scm_tool = SVN.new url
    end
    
    def zip
      @pack_tool = ZipTool.new
    end
    
  end    
  
end
