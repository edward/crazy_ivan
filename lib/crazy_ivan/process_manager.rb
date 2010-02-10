require 'lockfile'

class AlreadyRunningError < StandardError; end

class ProcessManager
  @@lockfile = Lockfile.new('/tmp/crazy_ivan.lock', :retries => 1)
  
  def self.lockfilepath=(filepath)
    @@lockfile = Lockfile.new(filepath, :retries => 1)
  end
  
  def self.acquire_lock!
    lock
    yield
  ensure
    unlock
  end
  
  def self.unlock
    @@lockfile.unlock
  rescue Lockfile::UnLockError
  end
  
  def self.lock
    Syslog.debug "Acquiring lock"
    @@lockfile.lock
    Syslog.debug("Locked CI process")
  rescue Lockfile::LockError
    msg = "Detected another running CI process - cannot start"
    Syslog.warning msg
    puts msg
    raise AlreadyRunningError, msg
  end
end