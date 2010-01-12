begin
  require 'json'
rescue LoadError
  $LOAD_PATH.unshift(File.dirname(__FILE__) + '/json-1.1.7/lib')
  require 'json'
end