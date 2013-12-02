require 'config'

class Tool
  
  attr_reader :name
  
  def initialize name, load_path=true
    @name = name
    @load_path = load_path
    @path = nil
  end
  
  def path
    if @path.nil? then
      if @load_path then
        @path = Jud::Config.instance.config['tools'][@name]['path']
        if @path.nil? or @path.empty? then
          @path = $platform.find_executable @name
          Jud::Config.instance.config['tools'][@name]['path'] = @path
        end
      else
        abort('No path for ' + @name)
      end
    end
    return @path
  end
  
end
