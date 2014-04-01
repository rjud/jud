require 'submit_tool'

require 'erb'
require 'open3'

class CTest < SubmitTool
  
  CTest.configure
  
  attr_reader :native_build_tool
  
  def initialize options = {}
    super()
    @native_build_tool = native_build_tool
  end
  
  def submit srcdir, builddir, prefix, build_type, buildname, options={}
    # Generate the CTest scripting file
    dirname = Pathname.new(__FILE__).realpath.dirname
    template_filename = dirname.join 'ctest.cmake.erb'
    template_file = File.open(template_filename, 'r').read
    erb = ERB.new template_file, nil, '-'
    Dir.mkdir builddir if not File.directory? builddir
    script_filename = Pathname.new(builddir).join "ctest-#{build_type}.cmake"
    File.open script_filename, 'w+' do |file|
      begin
        text = erb.result binding
      rescue => e
        msg = "While binding to #{template_filename}, can't generate #{script_filename}:\n #{e}"
        raise Error, msg
      else
        file.write text
      end
    end
    # Call CTest
    cmd = '"' + path + '" -V -S ' + script_filename.to_s
    exit_status = Platform.execute cmd, safe: true, keep: '!!!!'
    if exit_status[0].success? then
      SubmitTool::OK
    elsif exit_status[1].match(/Configuration failed/) then
      SubmitTool::CONF_NOK
    elsif exit_status[1].match(/Build failed/) then
      SubmitTool::BUILD_NOK
    elsif exit_status[1].match(/Some tests failed/) then
      SubmitTool::TESTS_NOK
    else
      SubmitTool::NOK
    end
  end
  
end
