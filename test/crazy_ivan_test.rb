require 'test_helper'
require 'tmpdir'

class CrazyIvanTest < Test::Unit::TestCase
  def setup
    @results = {:project_name => 'some-project',
                :version => {:output => 'a-valid-version', :error => '', :exit_status => '0'},
                :update  => {:output => 'Updated successfully', :error => '', :exit_status => '0'},
                :test    => {:output => 'Some valid test results. No fails.', :error => '', :exit_status => '0'},
                :timestamp => ''}
  end
  
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
  
  # Does this test really work? I think it's wrong
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
    Open4.stubs(:popen4).with('.ci/update').yields(stub(),
                                                   stub(:close),
                                                   stub(:read => @results[:update][:output]),
                                                   stub(:read => @results[:update][:error])).returns(stub(:exitstatus => '0'))
    Open4.stubs(:popen4).with('.ci/version').yields(stub(),
                                                    stub(:close),
                                                    stub(:read => ''),
                                                    stub(:read => 'could not find the command you were looking for')).returns(stub(:exitstatus => '1'))
    Open4.stubs(:popen4).with('.ci/conclusion').yields(stub(),
                                                       stub(:puts => true, :close => true),
                                                       stub(),
                                                       stub(:read => '')).returns(stub(:exitstatus => '0'))
    
    setup_crazy_ivan do
      Dir.chdir('projects') do
        do_silently { CrazyIvan.generate_test_reports_in('../test-results') }
      end
      
      assert !File.exists?('test-results/some-project/nil.json')
    end
  end
  
  def test_conclusion_executed
    Open4.stubs(:popen4).with('.ci/update').yields(stub(),
                                                   stub(:close),
                                                   stub(:read => @results[:update][:output]),
                                                   stub(:read => @results[:update][:error])).returns(stub(:exitstatus => '0'))
    Open4.stubs(:popen4).with('.ci/version').yields(stub(),
                                                    stub(:close),
                                                    stub(:read => @results[:version][:output]),
                                                    stub(:read => @results[:version][:error])).returns(stub(:exitstatus => '0'))
    Open4.stubs(:popen4).with('.ci/test').yields(stub(),
                                                 stub(:close),
                                                 stub(:read => @results[:test][:output]),
                                                 stub(:read => @results[:test][:error])).returns(stub(:exitstatus => '0'))
    
    @results[:timestamp] = Time.now
    Time.stubs(:now => @results[:timestamp])
    
    fake_stdin = mock()
    
    fake_stdin.expects(:puts).with(@results.to_json).at_least_once
    fake_stdin.expects(:close)
    
    Open4.stubs(:popen4).with('.ci/conclusion').yields(stub(), fake_stdin, stub(), stub(:read => '')).returns(stub(:exitstatus => '0'))
    
    setup_crazy_ivan(false) do
      run_crazy_ivan
    end
  end
  
  # def test_report_in_progress_json_created
  #   setup_crazy_ivan do
  #     run_crazy_ivan
  #   end
  # end
  
  private
  
  def setup_crazy_ivan(with_multiple_projects = true)
    Dir.mktmpdir('continuous-integration') do |tmpdir|
      Dir.chdir(tmpdir)
      
      Dir.mkdir('projects')
      Dir.chdir('projects') do |projects_dir|
        Dir.mkdir('some-project')
        Dir.mkdir('some-other-project') if with_multiple_projects
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
    Open4.stubs(:popen4).with('.ci/update').yields(stub(),
                                                   stub(:close),
                                                   stub(:read => @results[:update][:output]),
                                                   stub(:read => @results[:update][:error])).returns(stub(:exitstatus => '0'))
    Open4.stubs(:popen4).with('.ci/version').yields(stub(),
                                                    stub(:close),
                                                    stub(:read => @results[:version][:output]),
                                                    stub(:read => @results[:version][:error])).returns(stub(:exitstatus => '0'))
    Open4.stubs(:popen4).with('.ci/test').yields(stub(),
                                                 stub(:close),
                                                 stub(:read => @results[:test][:output]),
                                                 stub(:read => @results[:test][:error])).returns(stub(:exitstatus => '0'))
    
    Open4.stubs(:popen4).with('.ci/conclusion').yields(stub(),
                                                       stub(:puts => true, :close => true),
                                                       stub(),
                                                       stub(:read => '')).returns(stub(:exitstatus => '0'))
  end
end