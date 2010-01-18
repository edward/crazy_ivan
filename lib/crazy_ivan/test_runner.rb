class TestRunner
  def initialize(project_path, report_assembler)
    @project_path = project_path
    @results = {:project_name => File.basename(@project_path),
                :version => {:output => '', :error => '', :exit_status => ''},
                :update  => {:output => '', :error => '', :exit_status => ''},
                :test    => {:output => '', :error => '', :exit_status => ''},
                :timestamp => {:start => nil, :finish => nil}}
    @report_assembler = report_assembler
  end
  
  attr_reader :results
  
  def project_name
    @results[:project_name]
  end

  def check_for_valid_scripts
    check_script('update')
    check_script('version')
    check_script('test')
    check_script('conclusion')
  end
  
  def script_path(name)
    script_path = File.join('.ci', name)
  end
  
  def check_script(name)
    script_path = script_path(name)
    
    Dir.chdir(@project_path) do
      if File.exists?(script_path)
        if !File.stat(script_path).executable?
          msg = "#{@project_path}/.ci/#{name} script not executable"
          Syslog.warning msg
          abort msg
        elsif File.open(script_path).read.empty?
          msg = "#{@project_path}/.ci/#{name} script empty"
          Syslog.warning msg
          abort msg
        end
      else
        msg = "#{@project_path}/.ci/#{name} script missing"
        Syslog.warning msg
        abort msg
      end
    end
  end
  
  def run_script(name, options = {})
    output = ''
    error = ''
    exit_status = ''
    
    Dir.chdir(@project_path) do
      status = Open4::popen4(script_path(name)) do |pid, stdin, stdout, stderr|
        stdin.close  # Close to prevent hanging if the script wants input
        
        stdout_not_done = true
        stderr_not_done = true
        
        while stdout_not_done && stderr_not_done do
          ready_io_streams = select( [stdout], nil, [stderr], 3600 )
            
          script_output = ready_io_streams[0].pop
          script_error = ready_io_streams[2].pop
          
          if script_output
            begin
              new_output = stdout.readpartial(4096)
              output << new_output
              print new_output
              
              if options[:stream_test_results?]
                @results[:test][:output] = output
                @report_assembler.update_project(self)
              end
            rescue EOFError
              stdout_not_done = false
            end
          end
          
          if script_error
            begin
              new_error = stderr.readpartial(4096)
              error << new_error
              print error
              
              if options[:stream_test_results?]
                @results[:test][:error] = error
                @report_assembler.update_project(self)
              end
            rescue EOFError
              stderr_not_done = false
            end
          end
        end
      end
      
      exit_status = status.exitstatus
    end
    
    return output.chomp, error.chomp, exit_status.to_s
  end
  
  def run_conclusion_script
    
    # REFACTOR do this asynchronously so the next tests don't wait on running the conclusion
    
    Dir.chdir(@project_path) do
      Syslog.debug "Passing report to conclusion script at #{script_path('conclusion')}"
      errors = ''
      status = Open4.popen4(script_path('conclusion')) do |pid, stdin, stdout, stderr|
        stdin.puts @results.to_json
        stdin.close
        errors = stderr.read
      end
      
      Syslog.err(errors) if status.exitstatus != '0'
      Syslog.debug "Finished executing conclusion script"
    end
    
  rescue Errno::EPIPE
    Syslog.err "Unknown issue in writing to conclusion script."
  end
  
  def start!
    # REFACTOR to just report whichever scripts are invalid
    check_for_valid_scripts
    
    @results[:timestamp][:start] = Time.now
    Syslog.info "Starting CI for #{project_name}"
  end
    
  def update!
    Syslog.debug "Updating #{project_name}"
    @results[:update][:output], @results[:update][:error], @results[:update][:exit_status] = run_script('update')
  end
  
  def version!
    if @results[:update][:exit_status] == '0'
      Syslog.debug "Acquiring build version for #{project_name}"
      @results[:version][:output], @results[:version][:error], @results[:version][:exit_status] = run_script('version')
    end
  end
  
  def test!
    if @results[:version][:exit_status] == '0'
      Syslog.debug "Testing #{@results[:project_name]} build #{@results[:version][:output]}"
      @results[:test][:output], @results[:test][:error], @results[:test][:exit_status] = run_script('test', :stream_test_results? => true)
    else
      Syslog.debug "Failed to test #{project_name}; version exit status was #{@results[:version][:exit_status]}"
    end
    
    @results[:timestamp][:finish] = Time.now
    run_conclusion_script
  end
  
  def finished?
    @results[:timestamp][:finish]
  end
  
  def still_building?
    !finished?
  end
end