require 'test_helper'
require 'tempfile'

class ProcessManagerTest < Test::Unit::TestCase
  def setup
    Syslog.open('crazy_ivan-testing', Syslog::LOG_PID | Syslog::LOG_CONS)
    ProcessManager.lockfilepath = File.expand_path('test-crazy-ivan.lock', Dir.tmpdir)
    ProcessManager.unlock
  end
  
  def teardown
    Syslog.close
  end
  
  def test_exclusive_lock!
    do_silently do
      ProcessManager.acquire_lock! do
        assert_raise AlreadyRunningError do
          ProcessManager.acquire_lock! {}
        end
      end
    end
  end
  
  def test_locking
    do_silently do
      assert_nothing_raised do
        assert ProcessManager.lock
      end
      
      assert_raise AlreadyRunningError do
        ProcessManager.lock
      end
      
      assert_nothing_raised do
        ProcessManager.unlock
        ProcessManager.lock
      end
    end
  end
end