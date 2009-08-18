require 'open3'

class TestRunner

  class Result < Struct.new(:project_name, :update_output, :version_output, :test_output, :update_errorcode, :test_errorcode)
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
  
  def check_script(name)
    script_path = File.join(@dir, '.ci', name)
    
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
    output = ''
    error = ''
    
    Open3.popen3(name) do |stdin, stdout, stderr|
      stdin.close  # Close to prevent hanging if the script wants input
      output = stdout.read
      error = stderr.read
    end
    
    return output, error
  end

  def invoke
    if valid?
      Dir.chdir(@dir) do
        
        project_name = @dir.split(File::SEPARATOR).last
        results = Result.new(project_name)
        
        results.version_output = run_script('version')
        results.update_output, results.update_errorcode = run_script('update')
        
        if results.update_errorcode.zero?
          results.test_output, results.test_errorcode = run_script('run-tests')
        end
        
        return results
      end
    end
  end
end