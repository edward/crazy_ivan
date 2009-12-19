require 'rubygems'
require 'test/unit'
require 'mocha'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'crazy_ivan'

class Test::Unit::TestCase
  def do_silently
    orig_stdout = $stdout
    $stdout = File.new('/dev/null', 'w')
    yield
    $stdout = orig_stdout
  end
end
