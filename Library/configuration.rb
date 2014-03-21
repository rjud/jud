class Configuration
  
  def initialize
    @apps = []
  end
  
  def apps
    if @apps.empty? then
      deps = {}
      # Compute the dependencies for each application
      self.class.apps.each do |name, options|
        app = Object.const_get name
        @apps << app
        deps[app] = app.new.depends options[:options]
      end
      # Determine the order to build the applications
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
    puts Platform.yellow("Build application " + app.name)
    app.new.install self.class.apps[app.name.to_sym][:version], self.class.apps[app.name.to_sym][:options]    
  end
  
  def submit
    self.apps.each do |app|
      a = app.new
      if a.class.submit_tool then
        puts Platform.yellow("Build and test application " + app.name)      
        a.submit self.class.apps[a.name.to_sym][:options]
      else
        puts Platform.red("Not tool to submit " + app.name + ", so only build it")
        a.install self.class.apps[a.name.to_sym][:options]
      end
    end
  end
  
  class << self
    
    def apps
      @apps ||= {}
    end
    
    def app application, args={}, &block
      apps[application.to_sym] = {:options => {}}
      apps[application.to_sym].merge! args
    end
    
  end
  
end
