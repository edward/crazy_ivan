require 'test_helper'
require 'tmpdir'

class CrazyIvanTest < Test::Unit::TestCase  
  def test_setup
    Dir.mkdir('test/projects/some-project')
    
    setup_crazy_ivan
    
    assert File.exists?('test/projects/some-project/.ci/update')
    assert File.exists?('test/projects/some-project/.ci/version')
    assert File.exists?('test/projects/some-project/.ci/test')
    assert File.exists?('test/projects/some-project/.ci/conclusion')
  ensure
    `rm -rf test/projects/some-project`
  end
  
  def test_runner
    setup_crazy_ivan
    run_crazy_ivan do
      assert File.exists?('test/ci-results/index.html')
      assert File.exists?('test/ci-results/projects.json')
      assert File.exists?('test/ci-results/completely-working/recent.json')
      assert File.exists?('test/ci-results/completely-working/currently_building.json')
      
      projects = JSON.parse(File.open('test/ci-results/projects.json').read)["projects"]
      assert_equal ["completely-working"], projects
      
      recent_versions = JSON.parse(File.read('test/ci-results/completely-working/recent.json'))["recent_versions"]
      assert_equal ["a-valid-version"], recent_versions
      
      test_results = JSON.parse(File.read('test/ci-results/completely-working/a-valid-version.json'))
      
      # {"timestamp"=>{"finish"=>"Fri Jan 29 11:51:00 -0500 2010", "start"=>"Fri Jan 29 11:51:00 -0500 2010"}, "version"=>{"output"=>"a-valid-version", "exit_status"=>nil, "error"=>""}, "project_name"=>"completely-working", "update"=>{"output"=>"a-valid-update", "exit_status"=>nil, "error"=>""}, "test"=>{"output"=>"Some valid test results. No fails.", "exit_status"=>nil, "error"=>""}}
      
      assert_equal "completely-working", test_results["project_name"]
      
      # FIXME use a time range here
      assert test_results["timestamp"]["start"]
      assert test_results["timestamp"]["finish"]
      
      assert test_results["update"]["output"]
      assert test_results["update"]["error"]
      assert test_results["update"]["exit_status"] == nil
      
      assert test_results["version"]["output"]
      assert test_results["version"]["error"]
      assert test_results["version"]["exit_status"] == nil
      
      assert test_results["test"]["output"]
      assert test_results["test"]["error"]
      assert test_results["test"]["exit_status"] == nil
    end
  end
  
  def test_external_scripts_not_overwritten
    setup_crazy_ivan
    
    FileUtils.copy('test/projects/completely-working/.ci/version', 'test/projects/completely-working/.ci/version_original')
    
    setup_crazy_ivan
    
    # the completely-working/.ci/version is different from the default setup, so it would
    # have been changed if external scripts were overwritten
    assert FileUtils.compare_file('test/projects/completely-working/.ci/version_original', 'test/projects/completely-working/.ci/version')
  ensure
    FileUtils.copy('test/projects/completely-working/.ci/version_original', 'test/projects/completely-working/.ci/version')
  end
  
  private
  
  def setup_crazy_ivan()
    Dir.chdir('test/projects') do
      do_silently { CrazyIvan.setup }
    end
  end
  
  def run_crazy_ivan
    Dir.chdir('test/projects') do
      do_silently { CrazyIvan.generate_test_reports_in('../ci-results') }
    end
    yield
  ensure
    `rm -rf test/ci-results`
  end
end