require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'fileutils'

$LOAD_PATH << 'lib'
require 'crazy_ivan'

include FileUtils

# version = CrazyIvan::VERSION
version = "1.0.0"
name = "crazy_ivan"

spec = Gem::Specification.new do |s|
  s.name = name
  s.version = version
  s.summary = 'Crazy Ivan (CI) is simplest possible continuous integration tool.'
  s.description = "Continuous integration should really just be a script that captures the output of running your project update & test commands and presents recent results in a static html page.

  By keeping test reports in json, per-project CI configuration in 3 probably-one-line scripts, things are kept simple, quick, and super extensible.

  Want to use git, svn, or hg? No problem.
  Need to fire off results to Campfire? It's built-in.

  CI depends on cron."
  s.authors = "Edward Ocampo-Gooding"
  
  s.email = 'edward@edwardog.net'
  s.homepage = "http://github.com/edward/crazy_ivan"
  s.executables = ["crazy_ivan", "test_report2campfire"]
  s.default_executable = "crazy_ivan"
  s.rubyforge_project = "crazy_ivan"

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  
  # s.files = Dir.glob("{bin,lib}/**/*")
  s.files = FileList['.gitignore', '*.gemspec', 'lib/**/*', 'bin/*', 'templates/**/*', '[A-Z]*', 'test/**/*'].to_a
  
  s.require_path = "lib"
  s.bindir = "bin"
  
  s.add_development_dependency('gemcutter', '>= 0.2.1')
  s.add_development_dependency('mocha')
  
  readme = File.read('README.rdoc')
  s.post_install_message = '\n' + readme[0...readme.index('== How this works')]
end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end

desc "Install #{name} gem (#{version})"
task :install => [ :test, :package ] do
  sh %{gem install pkg/#{name}-#{version}.gem}
end

desc "Uninstall #{name} gem"
task :uninstall => [ :clean ] do
  sh %{gem uninstall #{name}}
end

desc "Release #{name} gem (#{version})"
task :release => [ :test, :package ] do
  sh %{gem push pkg/#{name}-#{version}.gem}
end

task :default => :test

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end