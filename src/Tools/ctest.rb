require 'submit_tool'

require 'erb'
require 'open3'

class CTest < SubmitTool
  
  attr_reader :native_build_tool
  
  def initialize
    super('ctest')
    @native_build_tool = native_build_tool
  end
  
  def submit srcdir, builddir, prefix, build_type, options={}
    # Generate the CTest scripting file
    dirname = Pathname.new(__FILE__).realpath.dirname
    template_file = File.open((dirname.join 'ctest.cmake.erb'), 'r').read
    erb = ERB.new template_file, nil, '-'
    Dir.mkdir builddir if not File.directory? builddir
    script_filename = Pathname.new(builddir).join "ctest-#{build_type}.cmake"
    File.open script_filename, 'w+' do |file|
      file.write (erb.result binding)
    end
    # Call CTest
    cmd = '"' + path + '" -V -S ' + script_filename.to_s
    exit_status = $platform.execute cmd, nil, true, '!!!!'
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
