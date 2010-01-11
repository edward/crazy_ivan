begin
  require 'open4'
rescue LoadError
  require 'crazy_ivan/vendor/open4-1.0.1/lib/open4.rb'
end