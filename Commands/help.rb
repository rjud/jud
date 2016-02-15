module Jud
  def self.help
    puts 'jud'
    puts ' [branch <branch>]'
    puts ' [configure]'
    puts ' [build [<project>]]'
    puts ' [submit [CONTINUOUS|EXPERIMENTAL|NIGHTLY] [project]]'
    puts ' [deploy <project>]'
    puts ' [install [<app>] [+<opt>]*[-<opt>]*]'
    puts ' [option <path1> <pathn>* <value>'
    puts ' [options <project>]'
    puts ' [tag <tag>]'
    puts ' [tags]'
  end
end
