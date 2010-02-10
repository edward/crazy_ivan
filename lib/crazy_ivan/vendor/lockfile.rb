begin
  require 'lockfile'
rescue LoadError
  $LOAD_PATH.unshift(File.dirname(__FILE__) + '/lockfile-1.4.3/lib')
  require 'lockfile'
end