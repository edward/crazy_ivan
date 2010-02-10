require 'test_helper'
require 'tmpdir'

class CrazyIvanBinTest < Test::Unit::TestCase
  def setup
    ProcessManager.lockfilepath = File.expand_path('maintest-crazyivan.lock', Dir.tmpdir)
    ProcessManager.unlock
  end
  
  def test_process_exclusivity
    do_silently do
      FileUtils.mkdir_p('test/long-running-projects/some-long-running-project/.ci')

      Dir.chdir('test/long-running-projects') do
        fork do
          CrazyIvan::generate_test_reports_in('../ci-results')
        end
      end

      sleep 5

      Dir.chdir('test/projects') do
        assert_raise AlreadyRunningError do
          CrazyIvan::generate_test_reports_in('../ci-results')
        end
      end
    end
  ensure
    Process.wait
    `rm -rf ../ci-results`
  end
end