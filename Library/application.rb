class Application
  
  def initialize
    @apps = []
  end
  
  def apps
    if @apps.empty? then
      deps = {}
      # Compute the dependencies for each project
      self.class.apps.each do |name, options|
        app = Object.const_get name
        @apps << app
        deps[app] = project(app.name.to_sym).depends
      end
      # Determine the order to build the projects
      @apps.sort! do |app1, app2|
        if deps[app1].include? app2 then
          1
        elsif deps[app2].include? app1 then
          -1
        else
          0
        end
      end
    end
    @apps
  end
  
  def project sym
    if self.class.apps.has_key? sym then
      Object.const_get(sym.to_s).new self.class.apps[sym]
    else
      Object.const_get(sym.to_s).new {}
    end
  end
  
  def options sym
    self.class.apps[sym]
  end
  
  def update
    self.apps.each do |a|
      project(a.name.to_sym).update
    end
  end
  
  def build app = nil
    if app.nil? then
      self.apps.each do |a|
        build_one a
      end
    else
      a = Object.const_get app
      build_one a
    end
  end
  
  def build_one app
    puts Platform.yellow("Build project " + app.name)
    project(app.name.to_sym).install
  end
  
  def submit
    self.apps.each do |app|
      a = project(app.name.to_sym)
      if a.class.submit_tool then
        puts Platform.yellow("Build and test project " + app.name)      
        a.submit
      else
        puts Platform.red("Not tool to submit #{app.name}, so only build it")
        a.install
      end
    end
  end
  
  class << self
    
    def apps
      @apps ||= {}
    end
    
    def app project, args={}, &block
      apps[project.to_sym] = {:options => {}}
      apps[project.to_sym].merge! args
    end
    
  end
  
end
