begin
  require 'open4'
rescue LoadError
  $LOAD_PATH.unshift(File.dirname(__FILE__) + '/open4-1.0.1/lib')
  require 'open4.rb'
end