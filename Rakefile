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
    Need to fire off results to Campfire? It's built-in.

    CI depends on cron."
    gem.email = "edward@edwardog.net"
    gem.homepage = "http://github.com/edward/crazy_ivan"
    gem.authors = ["Edward Ocampo-Gooding"]
    gem.executables = ["crazy_ivan", "test_report2campfire"]
    gem.default_executable = "crazy_ivan"
    gem.files = FileList['.gitignore', '*.gemspec', 'lib/**/*', 'bin/*', 'templates/**/*', '[A-Z]*', 'test/**/*'].to_a
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  
  Jeweler::GemcutterTasks.new
  
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
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
