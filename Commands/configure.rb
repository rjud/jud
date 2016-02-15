module Jud
  def self.configure
    #if ($install + 'Tools').directory?
    #  ($install + 'Tools').each_child do |child|
    #    if child.directory?
    #     ENV['PATH'] = ($install + 'Tools' + child + 'bin').to_s + ";" + ENV['PATH']
    #   end
    # end
    #end
    Dir.glob ($juddir + 'Tools' + '*.rb').to_s do |rb|
      load rb
    end
    ObjectSpace.each_object(Class).select{ |c| c < Tool }.each do |c|      
      c.configure
    end
  end
end
