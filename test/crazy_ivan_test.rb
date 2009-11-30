require 'test_helper'
require 'tmpdir'

class CrazyIvanTest < Test::Unit::TestCase
  def test_setup
    setup_crazy_ivan do
      assert File.exists?('projects/some-project/.ci/update')
      assert File.exists?('projects/some-project/.ci/version')
      assert File.exists?('projects/some-project/.ci/test')
    end
  end
  
  def test_runner
    setup_external_scripts_to_all_be_successful
    
    setup_crazy_ivan do
      CrazyIvan.setup
      
      # crazy_ivan runs from the projects directory
      Dir.chdir('projects') do
        CrazyIvan.generate_test_reports_in('../test-results')
      end
      
      assert File.exists?('test-results/index.html')
      assert File.exists?('test-results/projects.json')
      assert File.exists?('test-results/some-project/recent.json')
      
      projects = JSON.parse(File.open('test-results/projects.json').read)["projects"]
      recent_versions = JSON.parse(File.open('test-results/some-project/recent.json').read)["recent_versions"]
      
      assert_equal 'some-project', projects.first
      assert_equal 'a-valid-version', recent_versions.first
    end
  end
  
  def setup_crazy_ivan
    Dir.mktmpdir('continuous-integration') do |tmpdir|
      Dir.chdir(tmpdir)
      
      Dir.mkdir('projects')
      Dir.chdir('projects') do |projects_dir|
        Dir.mkdir('some-project')
        CrazyIvan.setup
      end
      
      yield
    end
  end
  
  def setup_external_scripts_to_all_be_successful
    Open3.stubs(:popen3).with('.ci/version').yields(stub(:close), stub(:read => 'a-valid-version'), stub(:read => ''))
    Open3.stubs(:popen3).with('.ci/update').yields(stub(:close), stub(:read => 'Updated successfully.'), stub(:read => ''))
    Open3.stubs(:popen3).with('.ci/test').yields(stub(:close), stub(:read => 'Some valid test results. No fails.'), stub(:read => ''))
  end
end