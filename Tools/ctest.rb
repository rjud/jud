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
  
  def submit prj, srcdir, builddir, prefix, build_type, buildname, options={}
    # Generate the CTest scripting file
    dirname = Pathname.new(__FILE__).realpath.dirname
    template_filename = dirname.join 'ctest.cmake.erb'
    template_file = File.open(template_filename, 'r').read
    erb = ERB.new template_file, nil, '-'
    FileUtils.mkdir_p builddir if not File.directory? builddir
    script_filename = $build.join "ctest-#{prj.name}-#{build_type}.cmake"
    File.open script_filename, 'w+' do |file|
      begin
        text = erb.result binding
      rescue => e
        msg = "While binding to #{template_filename}, can't generate #{script_filename}: #{e}\n#{e.backtrace}"
        raise Error, msg
      else
        file.write text
      end
    end
    # Call CTest
    old_lang = ENV['LANG']
    ENV['LANG'] = 'en'
    cmd = '"' + path + '" -V -S ' + script_filename.to_s
    exit_status = Platform.execute cmd, safe: true, keep: '!!!!'
    ENV['LANG'] = old_lang
    # Parse exit
    if exit_status[0].success? then
      SubmitTool::OK
    elsif exit_status[1].size == 0 then
      SubmitTool::NOK
    elsif exit_status[1].last.match(/Configuration failed/) then
      SubmitTool::CONF_NOK
    elsif exit_status[1].last.match(/Build failed/) then
      SubmitTool::BUILD_NOK
    elsif exit_status[1].last.match(/Some tests failed/) then
      SubmitTool::TESTS_NOK
    else
      SubmitTool::NOK
    end
  end
  
end
