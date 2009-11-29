require 'open3'

class TestRunner

  class Result < Struct.new(:project_name, :update_output, :version_output, :test_output, :update_error, :test_error, :timestamp)
  end
  
  def initialize(project_path)
    @project_path = project_path
  end

  def valid?
    check_script('update')
    check_script('version')
    check_script('test')
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
  
  def invoke
    if valid?
      project_name = @project_path.split(File::SEPARATOR).last
      results = Result.new(project_name)
      
      results.version_output = run_script('version').join
      results.update_output, results.update_error = run_script('update')
      
      if results.update_error.empty?
        results.test_output, results.test_error = run_script('test')
      end
      
      results.timestamp = Time.now
      
      return results
    end
  end
end