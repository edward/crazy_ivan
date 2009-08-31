require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "crazy_ivan"
    gem.summary = 'Crazy Ivan (CI) is simplest possible continuous integration tool.'
    gem.description = "Continuous integration should really just be a script that captures the output of running your project update & test commands and presents recent results in a static html page.

    By keeping test reports in json, per-project CI configuration in 3 probably-one-line scripts, things are kept simple, quick, and super extensible.

    Want to use git, svn, or hg? No problem.
    Need to fire off results to Twitter or Campfire? It's one line away.

    CI depends on cron."
    gem.email = "edward@edwardog.net"
    gem.homepage = "http://github.com/edward/crazy_ivan"
    gem.authors = ["Edward Ocampo-Gooding"]
    gem.rubyforge_project = "crazyivan"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Crazy Ivan #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
