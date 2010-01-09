require 'open3'

class TestRunner
  
  # # REFACTOR this to just be a Hash
  # class Result < Struct.new(:project_name, :version_output, :update_output, :test_output, :version_error, :update_error, :test_error, :exit_status, :timestamp)
  #   def to_json
  #     { "project_name" => project_name,
  #       "version" => [version_error, version_output].join,
  #       "timestamp" => timestamp,
  #       "update" => update_output,
  #       "update_error" => update_error,
  #       "test" => test_output,
  #       "test_error" => test_error,
  #       "exit_status" => exit_status
  #     }.to_json
  #   end
  # end
  
  def initialize(project_path)
    @project_path = project_path
    @results = {:project_name => '',
                :version => {:output => '', :error => '', :exit_status => ''},
                :update  => {:output => '', :error => '', :exit_status => ''},
                :test    => {:output => '', :error => '', :exit_status => ''},
                :timestamp => ''}
                # :timestamp => {:start => '', :finish => ''}}
  end

  def valid?
    check_script('update')
    check_script('version')
    check_script('test')
    check_script('conclusion')
    return true
  end
  
  def script_path(name)
    script_path = File.join('.ci', name)
  end
  
  def check_script(name)
    script_path = script_path(name)
    
    Dir.chdir(@project_path) do
      if File.exists?(script_path)
        if !File.stat(script_path).executable?
          abort "#{@project_path}/.ci/#{name} script not executable"
        elsif File.open(script_path).read.empty?
          abort "#{@project_path}/.ci/#{name} script empty"
        end
      else
        abort "#{@project_path}/.ci/#{name} script missing"
      end
    end
  end
  
  def run_script(name)
    output = ''
    error = ''
    exit_status = ''
    
    Dir.chdir(@project_path) do
      status = Open4::popen4(script_path(name)) do |pid, stdin, stdout, stderr|
        stdin.close  # Close to prevent hanging if the script wants input
        output = stdout.read
        error = stderr.read
      end
      
      exit_status = status.exitstatus
    end
    
    return output.chomp, error.chomp, exit_status.to_s
  end
  
  def run_conclusion
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
  end
  
  def invoke
    if valid?
      @results[:project_name] = File.basename(@project_path)
      
      Syslog.info "Running tests for #{@results[:project_name]}"
      
      @results[:version][:output], @results[:version][:error], @results[:version][:exit_status] = run_script('version')
      
      if @results[:version][:exit_status] == '0'
        @results[:update][:output], @results[:update][:error], @results[:update][:exit_status] = run_script('update')
        
        if @results[:update][:exit_status] == '0'
          @results[:test][:output], @results[:test][:error], @results[:test][:exit_status] = run_script('test')
        end
      end
      
      @results[:timestamp] = Time.now
      
      run_conclusion
      
      return @results
    end
  end
end