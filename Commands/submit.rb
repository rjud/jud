module Jud
  def self.submit
    require 'submit_tool'
    mode = SubmitTool::EXPERIMENTAL
    prjname = nil
    while ARGV.length > 0
      case ARGV.first
      when '--mode'
        ARGV.shift
        arg = ARGV.shift
        if arg == 'EXPERIMENTAL'
          mode = SubmitTool::EXPERIMENTAL
        elsif arg == 'CONTINUOUS'
          mode = SubmitTool::CONTINUOUS
        elsif arg == 'NIGHTLY'
          mode = SubmitTool::NIGHTLY
        else
          puts (Platform.red "Unknow mode #{arg}")
          exit 1
        end
      else
        prjname = ARGV.shift
      end
    end
    Application.submit $appname, $prjname, { :mode => mode }
  end
end
