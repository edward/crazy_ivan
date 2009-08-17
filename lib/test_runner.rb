require 'open3'

class TestRunner

  class Result < Struct.new(:project_name, :update_output, :test_output, :update_errorcode, :test_errorcode)
  end
  
  def initialize(dir)
    @dir = dir
  end

  def valid?
    if File.stat(@dir, '.ci', 'update').executable?
      fail "#{@dir}/.ci directory update script missing or not executable"
    end
    
    if File.stat(@dir, '.ci', 'version').executable?
      fail "#{@dir}/.ci directory version script missing or not executable"
    end
    
    if File.stat(@dir, '.ci', 'run-tests').executable?
      fail "#{@dir}/.ci directory run-tests script missing or not executable"
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
      Dir.chdir(dir) do
        
        project_name = dir.split(File::SEPARATOR).last
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