# Prefer gems to the bundled libs.
require 'rubygems'

begin
  gem 'json', '~> 1.1.7'
rescue LoadError
  $:.unshift "#{File.dirname(__FILE__)}/json-1.1.7"
end

require 'json'