require 'submit_tool'

require 'erb'
require 'open3'

module Jud::Tools
  class CTest < SubmitTool
    
    attr_reader :native_build_tool
    
    class << self
      attr_reader :modes
    end
    
    @modes = { EXPERIMENTAL => 'Experimental', NIGHTLY => 'Nightly', CONTINUOUS => 'Continuous' }
    
    def initialize options={}
      super options
      @native_build_tool = native_build_tool
    end
    
    def get_options srcdir, builddir, prefix, build_type, prj, mode, options={}
      resolved_options = @build_tool.get_options srcdir, builddir, prefix, build_type, prj, options
      if Platform.is_linux? and build_type == :Debug and mode == NIGHTLY
        resolved_options << BuildTool::ResolvedOption.new('CMAKE_CXX_FLAGS', :STRING, true, '-O0 -fPIC -fprofile-arcs -ftest-coverage ', nil)
        resolved_options << BuildTool::ResolvedOption.new('CMAKE_C_FLAGS', :STRING, true, '-O0 -fPIC -fprofile-arcs -ftest-coverage ', nil)
        resolved_options << BuildTool::ResolvedOption.new('CMAKE_EXE_LINKER_FLAGS', :STRING, true, '-fprofile-arcs -ftest-coverage', nil)
      end
      resolved_options
    end
    
    def submit prj, srcdir, builddir, prefix, build_type, buildname, mode, options={}
      # Generate the CTest scripting file
      dirname = Pathname.new(__FILE__).realpath.dirname
      template_filename = dirname.join 'ctest.cmake.erb'
      template_file = File.open(template_filename, 'r').read
      erb = ERB.new template_file, nil, '-'
      FileUtils.mkdir_p builddir if not File.directory? builddir
      script_filename = $build.join "ctest-#{prj.name}-#{build_type}-#{CTest.modes[mode]}.cmake"
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
      # Open the file CTestConfig.cmake to get the URL.
      url = ''
      File.open (srcdir + 'CTestConfig.cmake').to_s, 'r' do |file|
        while line = file.gets
          if /^set\(CTEST_DROP_METHOD "(?<protocol>.*)"\)/ =~ line
            url += protocol + '://'
          end
          if /^set\(CTEST_DROP_SITE "(?<site>.*)"\)/ =~ line
            url += site if defined? site
          end
        end
      end
      # Call CTest
      old_lang = ENV['LANG']
      ENV['LANG'] = 'en'
      Platform.set_env_proxy if Platform.use_proxy? url
      cmd = '"' + path + '" -V -S ' + script_filename.to_s
      exit_status = Platform.execute cmd, safe: true, keep: '!!!!'
      Platform.unset_env_proxy if Platform.use_proxy? url
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
end
