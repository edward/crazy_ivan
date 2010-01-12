if !File.respond_to?(:mktmpdir)
  require File.dirname(__FILE__) + '/core_ext/tmpdir'
end