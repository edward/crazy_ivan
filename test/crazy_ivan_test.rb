require 'test_helper'
require 'tmpdir'

class CrazyIvanTest < Test::Unit::TestCase
  def setup
    @results = TestRunner::Result.new
    @results.version_output = 'a-valid-version'
    @results.version_error = ''
    @results.update_output = 'Updated successfully'
    @results.update_error = ''
    @results.test_output = 'Some valid test results. No fails.'
    @results.test_error = ''
  end
  
  def test_setup
    setup_crazy_ivan do
      assert File.exists?('projects/some-project/.ci/version')
      assert File.exists?('projects/some-project/.ci/update')
      assert File.exists?('projects/some-project/.ci/test')
    end
  end
  
  def test_runner
    setup_external_scripts_to_all_be_successful
    
    setup_crazy_ivan do
      run_crazy_ivan
      
      assert File.exists?('test-results/index.html')
      assert File.exists?('test-results/projects.json')
      assert File.exists?('test-results/some-project/recent.json')
      
      projects = JSON.parse(File.open('test-results/projects.json').read)["projects"]
      recent_versions = JSON.parse(File.open('test-results/some-project/recent.json').read)["recent_versions"]
      
      assert_equal 2, projects.size
      assert projects.include?('some-project')
      assert_equal 'a-valid-version', recent_versions.first
    end
  end
  
  def test_external_scripts_not_overwritten
    setup_external_scripts_to_all_be_successful
    
    setup_crazy_ivan do
      File.open('projects/some-project/.ci/version', 'a') do |file|
        file << "a change to the script"
      end

      FileUtils.copy('projects/some-project/.ci/version', 'projects/some-project/.ci/version_original')
      
      do_silently { CrazyIvan.setup }
      
      assert FileUtils.compare_file('projects/some-project/.ci/version_original', 'projects/some-project/.ci/version')
    end
  end
  
  def test_nil_reports_not_created
    Open3.stubs(:popen3).with('.ci/version').yields(stub(:close), stub(:read => ''), stub(:read => 'could not find the command you were looking for'))
    Open3.stubs(:popen3).with('.ci/conclusion').yields(stub(:puts), stub(), stub(:read => ''))
    
    setup_crazy_ivan do
      Dir.chdir('projects') do
        do_silently { CrazyIvan.generate_test_reports_in('../test-results') }
      end
      
      assert !File.exists?('test-results/some-project/nil.json')
    end
  end
  
  def test_conclusion_executed
    Open3.stubs(:popen3).with('.ci/version').yields(stub(:close), stub(:read => @results.version_output), stub(:read => @results.version_error))
    Open3.stubs(:popen3).with('.ci/update').yields(stub(:close), stub(:read => @results.update_output), stub(:read => @results.update_error))
    Open3.stubs(:popen3).with('.ci/test').yields(stub(:close), stub(:read => @results.test_output), stub(:read => @results.test_error))
    
    @results.timestamp = Time.now
    Time.stubs(:now => @results.timestamp)
    
    fake_stdin = mock()
    fake_stdin.expects(:puts).with(@results.to_json).at_least_once
    
    Open3.stubs(:popen3).with('.ci/conclusion').yields(fake_stdin, stub(), stub(:read => ''))
    
    setup_crazy_ivan do
      run_crazy_ivan
    end
  end
  
  private
  
  def setup_crazy_ivan
    Dir.mktmpdir('continuous-integration') do |tmpdir|
      Dir.chdir(tmpdir)
      
      Dir.mkdir('projects')
      Dir.chdir('projects') do |projects_dir|
        Dir.mkdir('some-project')
        Dir.mkdir('some-other-project')
        do_silently { CrazyIvan.setup }
      end
      
      yield
    end
  end
  
  def run_crazy_ivan
    # crazy_ivan runs from the projects directory
    Dir.chdir('projects') do
      do_silently { CrazyIvan.generate_test_reports_in('../test-results') }
    end
  end
  
  def setup_external_scripts_to_all_be_successful
    Open3.stubs(:popen3).with('.ci/version').yields(stub(:close), stub(:read => @results.version_output), stub(:read => @results.version_error))
    Open3.stubs(:popen3).with('.ci/update').yields(stub(:close), stub(:read => @results.update_output), stub(:read => @results.update_error))
    Open3.stubs(:popen3).with('.ci/test').yields(stub(:close), stub(:read => @results.test_output), stub(:read => @results.test_error))
    
    Open3.stubs(:popen3).with('.ci/conclusion').yields(stub(:puts), stub(), stub(:read => ''))
  end
end