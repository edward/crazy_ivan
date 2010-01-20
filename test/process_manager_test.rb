require 'test_helper'
require 'tempfile'

class ProcessManagerTest < Test::Unit::TestCase
  def setup
    Syslog.open('crazy_ivan-testing', Syslog::LOG_PID | Syslog::LOG_CONS)
    ProcessManager.pidfile = File.expand_path('test-crazyivan.pid', Dir.tmpdir)
  end
  
  def test_exclusive_lock
    ProcessManager.lock_exclusively!
    
    Process.expects(:kill)
    ProcessManager.lock_exclusively!
  end
end