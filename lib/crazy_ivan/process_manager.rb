class ProcessManager
  @@pidfile = '/tmp/crazy_ivan.pid'
  
  def self.pidfile=(file)
    @@pidfile = file
  end
  
  def self.acquire_lock
    lock_exclusively!
    yield
    unlock
  end
  
  def self.unlock
    File.new(@@pidfile).flock(File::LOCK_UN)
  end

  def self.ci_already_running?
    File.exists?(@@pidfile) && !File.new(@@pidfile).flock(File::LOCK_EX | File::LOCK_NB)
  end
  
  def self.lock_exclusively!(options = {})
    pid = Integer(File.read(@@pidfile)) if File.exists?(@@pidfile)
    
    Syslog.debug "Acquiring lock"
    
    if options[:interrupt_existing_process]
      File.open(@@pidfile, "w+") { |fp| fp << Process.pid }

      if ci_already_running?
        Process.kill("INT", pid)
        Syslog.debug("Detected another running CI process #{pid}; interrupting it and starting myself")
        File.new(@@pidfile).flock(File::LOCK_EX)
      end
    else
      if ci_already_running?
        msg = "Detected another running CI process #{pid} - terminating myself"
        Syslog.warning msg
        puts msg
        Process.kill("INT", 0)
      else
        Syslog.debug("Locked CI process pid file")
        Syslog.debug("Writing to pid file with #{Process.pid}")
        File.open(@@pidfile, "w+") { |fp| fp << Process.pid }
      end
    end
  end
end