require 'config'

class Application
  
  class Error < RuntimeError; end
  
  attr_reader :name, :packdir
  
  def initialize
    self.class.languages.uniq!
    @name = self.class.name
    @app_config = $platform_config['applications']
    @config = @app_config[@name] 
    @install = prefix # How to give options
    @packdir = $packdir
  end
  
  def build_name
    case self.class.languages.size
    when 0 then
      return $platform.build_name
    when 1 then
      language = self.class.languages.first
      composite = $platform.get_composite_for_language(language)
      return composite.build_name
    else
      name = $platform.build_name
      self.class.languages.each do |language|
        composite = $platform.get_composite_for_language language
        name += '-' + composite.short_build_name
      end
      return name
    end
  end
  
  def srcdir build_type, options
    dir = @name
    dir += "-#{options[:version]}" if options.has_key? :version
    $src.join dir
  end
  
  def builddir build_type, options
    dir = @name
    dir += "-#{options[:version]}" if options.has_key? :version
    dir += "-#{build_name}"
    dir += "-#{build_type.downcase}" if build_type
    $build.join dir
  end
  
  def prefix options={}
    config = @app_config['separate_install_trees']
    unless config.boolean? then
      config = true
      @app_config['separate_install_trees'] = config = true
    end
    if config then
      dir = @name
      #dir += "-#{options[:version]}" if options.has_key? :version
      dir += "-#{build_name}"
      prefix = $install.join dir
    else
      prefix = $install
    end
    prefix
  end
  
  def update options
    build_types.each do |bt|
      update_this bt, options[self.class.name.to_sym]
    end
  end
  
  def install_dependency claz, options
    depend = claz.new
    options_this = options[claz.name.to_sym]
    if depend.packfile(options_this).exist? then
      depend.unpack_this options_this
    elsif depend.class.repository and depend.class.repository.exist? depend.packfile(options_this) then
      depend.download_this options_this
      depend.unpack_this options_this
    else
      puts Platform.yellow('[' + name + "] install dependency " + depend.name)
      depend.install_dependencies options
      build_types.each do |bt|
        depend.checkout_this bt, options_this
        depend.configure_this bt, options_this
        depend.build_this bt, options_this
        depend.install_this bt, options_this
      end
      depend.pack_and_upload_this options_this
      puts Platform.yellow("[#{name}] dependency #{depend.name} is installed")
    end
    depend.register_this options_this
  end
  
  def install_dependencies options
    self.class.depends.each do |depend, cond|
      install = cond.nil? || (options[self.class.name.to_sym] && options[self.class.name.to_sym][:options][cond])
      config = @app_config[depend.name]
      install = (not config.has_key? 'prefix') if install
      install_dependency depend, options if install
    end
  end
  
  def checkout_this build_type, options
    src = srcdir build_type, options
    if not File.directory? src then
      version = options[:version]
      if not self.class.alternate_scm_tool.nil? then
        self.class.scm_tool.checkout src, version, {:safe => true}
        self.class.alternate_scm_tool.checkout src, version
      else
        self.class.scm_tool.checkout src, version
      end
    end
  end
  
  def update_this build_type, options
    src = srcdir build_type, options
    if File.directory? src then
      self.class.scm_tool.update src
    else
      checkout_this build_type, options
    end
  end
  
  def configure_this build_type, options
    if self.class.build_tool.nil? then return end
    src = srcdir build_type, options
    build = builddir build_type, options
    self.class.build_tool.configure src, build, @install, build_type, options[:options]
  end
  
  def build_types
    [:Debug, :Release] + self.class.build_types
  end
  
  def build_this build_type, options
    if self.class.build_tool.nil? then return end
    self.class.build_tool.build (builddir build_type, options)
  end
  
  def install_this build_type, options
    if self.class.build_tool.nil? then return end
    self.class.build_tool.install (builddir build_type, options)
  end
  
  def register_this options
    @config['prefix'] = @install.to_s
  end
  
  def install options
    install_dependencies options
    options[self.class.name] = {} if not options.has_key? self.class.name
    options_this = options[self.class.name.to_sym]
    build_types.each do |bt|
      checkout_this bt, options_this
      configure_this bt, options_this
      build_this bt, options_this
      install_this bt, options_this
    end
    pack_and_upload_this options_this
    register_this options_this
  end
  
  def submit options={}
    install_dependencies options
    options_this = options[self.class.name.to_sym]
    self.class.submit_tool.build_tool = self.class.build_tool
    self.class.submit_tool.scm_tool = self.class.scm_tool
    status = SubmitTool::OK
    build_types.each do |bt|
      src = srcdir bt, options_this
      build = builddir bt, options_this
      buildname = "#{options_this[:version]} " if options_this.has_key? :version
      buildname += "#{build_name}"
      self.class.scm_tool.checkout src if not File.directory? src
      s = self.class.submit_tool.submit src, build, @install, bt, buildname, options_this[:options]
      status = s if s > status
    end
    pack_and_upload_this options_this if pack? status
    @config['prefix'] = @install.to_s
  end
  
  def pack? status
    case status
    when SubmitTool::OK then true
    when SubmitTool::TESTS_NOK then true
    else false
    end
  end
  
  def packfilename options
    filename = @name
    filename += "-#{options[:version]}" if options.has_key? :version
    filename += "-#{build_name}"
    filename += ".#{self.class.pack_tool.ext}"
    filename
  end
  
  def packfile options
    Pathname.new(@packdir).join(packfilename options)
  end
  
  def pack_and_upload_this options
    pack_this options
    upload_this options if self.class.repository
  end
  
  def pack_this options
    puts Platform.blue("Pack #{packfile(options).basename.to_s}")
    self.class.pack_tool.pack packfile(options), @install
  end
  
  def unpack_this options
    puts Platform.blue("Unpack #{packfile.basename.to_s} to #{@install.to_s}")
    self.class.pack_tool.unpack packfile(options), @install
  end
  
  def download_this options
    self.class.repository.download packfile(options)
  end
  
  def upload_this options
    if self.class.repository.exist? packfile(options) then
      self.class.repository.delete packfile(options)
    end
    self.class.repository.upload packfile(options)
  end
  
  def depends options={}
    depends = []
    self.class.depends.each do |depend, cond|
      depends << depend if cond.nil? or options[cond.to_sym]
    end
    depends
  end
    
  class << self
    
    attr_reader :scm_tool, :alternate_scm_tool, :languages, :build_tool, :submit_tool, :repository
    
    def pack_tool
      zip
      @pack_tool
    end
    
    def languages
      @languages ||= []
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
    
    def c
      require 'c'
      languages << Jud::C
    end
    
    def cxx
      require 'cxx'
      languages << Jud::Cxx
    end
    
    def java
      languages << Java
    end
    
    def cmake &block
      require 'cmake'
      @build_tool= CMake.new
      @build_tool.instance_eval &block if block_given? &block
    end
    
    def ctest &block
      require 'ctest'
      @submit_tool = CTest.new
      @submit_tool.instance_eval &block if block_given? &block
    end
    
    def cvs url, modulename
      require 'cvs'
      @scm_tool = CVS.new url, modulename
    end
    
    def git url
      require 'git'
      @scm_tool = Git.new url
    end
    
    def redmine url, projectid
      require 'redmine'
      @repository = Redmine.new url, projectid
    end
    
    def svn url
      require 'svn'
      @scm_tool = SVN.new url
    end
    
    def wget url, packtool
      require 'wget'
      @alternate_scm_tool = Wget.new url, packtool
    end
    
    def zip
      require 'ziptool'
      @pack_tool = ZipTool.new
    end
    
  end
  
end
