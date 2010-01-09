# Prefer gems to the bundled libs.
require 'rubygems'

begin
  gem 'open4', '>= 1.0.1'
rescue LoadError
  $:.unshift "#{File.dirname(__FILE__)}/open4-1.0.1"
end

require 'open4'