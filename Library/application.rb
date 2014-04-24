module Application
  
  $all_apps = {}
  $apps = []
  
  def app project, args={}, &block
    $all_apps[project.to_sym] = { :application => self.to_s, :options => {} }
    $all_apps[project.to_sym].merge! args
  end
  
  def apps
    if $apps.empty? then
      deps = {}
      # Compute the dependencies for each project
      all_apps.each do |name, options|
        app = Object.const_get name
        $apps << app
        deps[app] = project(app.name.to_sym).depends
      end
      # Determine the order to build the projects
      $apps.sort! do |app1, app2|
        if deps[app1].include? app2 then
          1
        elsif deps[app2].include? app1 then
          -1
        else
          0
        end
      end
    end
    $apps
  end
  
  def project sym
    if $all_apps.has_key? sym then
      Object.const_get(sym.to_s).new $all_apps[sym]
    else
      Object.const_get(sym.to_s).new {}
    end
  end
  
  def options sym
    $all_apps[sym]
  end
  
  def update
    $apps.each do |a|
      project(a.name.to_sym).update
    end
  end
  
  def build app = nil
    if app.nil? then
      $apps.each do |a|
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
    $apps.each do |app|
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
    
end
