class TestRunner

  class Result < Struct.new(:setup, :test_output, :setup_errorcode, :test_errorcode)
  end


  def initialize(dir)
    @dir = dir
  end
  
  def valid?
    if File.stat(@dir, '.ci', 'setup').executable?
      fail "#{name} .ci directory setup script missing or not executable"            
    end

    if File.stat(@dir, '.ci', 'version').executable?
      fail "#{name} .ci directory version script missing or not executable"            
    end

    if File.stat(@dir, '.ci', 'run-tests').executable?
      fail "#{name} .ci directory run-tests script missing or not executable"            
    end
  end
  
  def run_script
    popen(...) 
    
    return output, $?
  end
  
  
  def invoke
    if valid?
      Dir.chdir(dir) do
        results = Result.new
        results.version = run_script('version')
        results.setup, results.setup_errorcode = run_script('setup')
        if results.setup_errorcode.zero?
          results.output, results.test_errorcode = run_script('run-tests')
        end
      end    
    end
  end
  
end
