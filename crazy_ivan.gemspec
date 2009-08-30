require 'rubygems'

spec = Gem::Specification.new do |spec|
  spec.name = 'crazy_ivan'
  spec.summary = 'Crazy Ivan (CI) is simplest possible continuous integration tool.'
  spec.description = "Continuous integration should really just be a script that captures the output of running your project update & test commands and presents recent results in a static html page.
  
  By keeping test reports in json, per-project CI configuration in 3 probably-one-line scripts, things are kept simple, quick, and super extensible.
  
  Want to use git, svn, or hg? No problem.
  Need to fire off results to Twitter or Campfire? It's one line away.
  
  CI depends on cron."
  spec.author = 'Edward Ocampo-Gooding'
  spec.email = 'edward@edwardog.net'
  spec.homepage = 'http://github.com/edward/crazy_ivan/tree/master'
  spec.files = Dir['bin/crazy_ivan', 'lib/*.rb', 'templates/**/*', 'README.rdoc', 'LICENSE', 'Rakefile', 'TODO', 'VERSION']
  spec.executables = ['crazy_ivan']
  spec.version = '0.1.0'
end