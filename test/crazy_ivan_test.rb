require 'test_helper'
require 'tmpdir'

class CrazyIvanTest < Test::Unit::TestCase
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
      # crazy_ivan runs from the projects directory
      Dir.chdir('projects') do
        do_silently { CrazyIvan.generate_test_reports_in('../test-results') }
      end
      
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
    
    setup_crazy_ivan do
      Dir.chdir('projects') do
        do_silently { CrazyIvan.generate_test_reports_in('../test-results') }
      end
      
      assert !File.exists?('test-results/some-project/nil.json')
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
  
  def setup_external_scripts_to_all_be_successful
    Open3.stubs(:popen3).with('.ci/version').yields(stub(:close), stub(:read => 'a-valid-version'), stub(:read => ''))
    Open3.stubs(:popen3).with('.ci/update').yields(stub(:close), stub(:read => 'Updated successfully.'), stub(:read => ''))
    Open3.stubs(:popen3).with('.ci/test').yields(stub(:close), stub(:read => 'Some valid test results. No fails.'), stub(:read => ''))
  end
  
  def do_silently
    orig_stdout = $stdout
    $stdout = File.new('/dev/null', 'w')
    yield
    $stdout = orig_stdout
  end
end