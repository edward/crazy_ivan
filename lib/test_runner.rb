require 'open3'

class TestRunner

  class Result < Struct.new(:project_name, :update_output, :version_output, :test_output, :update_error, :test_error)
  end
  
  def initialize(dir)
    @dir = dir
  end

  def valid?
    check_script('update')
    check_script('version')
    check_script('run-tests')
    return true
  end
  
  def script_path(name)
    File.join(@dir, '.ci', name)
  end
  
  def check_script(name)
    script_path = script_path(name)
    
    if File.exists?(script_path)
      if !File.stat(script_path).executable?
        abort "#{@dir}/.ci/#{name} script not executable"
      end
    else
      abort "#{@dir}/.ci/#{name} script missing"
    end
    
    if File.open(script_path).read.empty?
      abort "#{@dir}/.ci/#{name} script empty"
    end
  end
  
  def run_script(name)
    script_path = script_path(name)
    output = ''
    error = ''
    
    Open3.popen3(script_path) do |stdin, stdout, stderr|
      stdin.close  # Close to prevent hanging if the script wants input
      output = stdout.read
      error = stderr.read
    end
    
    return output.chomp, error.chomp
  end

  def invoke
    if valid?
      project_name = @dir.split(File::SEPARATOR).last
      results = Result.new(project_name)
      
      results.version_output = run_script('version').join
      results.update_output, results.update_error = run_script('update')
      
      if results.update_error.empty?
        results.test_output, results.test_error = run_script('run-tests')
      end
      
      return results
    end
  end
end