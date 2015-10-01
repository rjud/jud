require 'Projects/ant'

include Application

module Tools
  prj :Ant, :version => '1.9.4', :tag => 'ANT_194'
  prj :Ninja, :version => '1.6.0'
end
