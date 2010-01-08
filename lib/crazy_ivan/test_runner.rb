require 'open3'

class TestRunner
  
  # REFACTOR this to just be a Hash
  class Result < Struct.new(:project_name, :version_output, :update_output, :test_output, :version_error, :update_error, :test_error, :timestamp)
    def to_json
      { "project_name" => project_name,
        "version" => [version_error, version_output].join,
        "timestamp" => timestamp,
        "update" => update_output,
        "update_error" => update_error,
        "test" => test_output,
        "test_error" => test_error
      }.to_json
    end
  end
  
  def initialize(project_path)
    @project_path = project_path
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
    
    Dir.chdir(@project_path) do
      Open3.popen3(script_path(name)) do |stdin, stdout, stderr|
        stdin.close  # Close to prevent hanging if the script wants input
        output = stdout.read
        error = stderr.read
      end
    end
    
    return output.chomp, error.chomp
  end
  
  def run_conclusion(results)
    Dir.chdir(@project_path) do
      Syslog.debug "Passing report to conclusion script at #{script_path('conclusion')}"
      Open3.popen3(script_path('conclusion')) do |stdin, stdout, stderr|
        stdin.puts results.to_json
        stdin.close
        errors = stderr.read
        Syslog.err(errors) if !errors.empty?
      end
      Syslog.debug "Finished executing conclusion script"
    end
  end
  
  def invoke
    if valid?
      project_name = File.basename(@project_path)
      results = Result.new(project_name)
      Syslog.info "Running tests for #{results.project_name}"
      
      results.version_output, results.version_error = run_script('version')
      
      if results.version_error.empty?
        results.update_output, results.update_error = run_script('update')
        
        if results.update_error.empty?
          results.test_output, results.test_error = run_script('test')
        else
          results.test_output, results.test_error = '', ''
        end
      else
        results.update_output, results.update_error = '', ''
      end
      
      results.timestamp = Time.now
      
      run_conclusion(results)
      
      return results
    end
  end
end