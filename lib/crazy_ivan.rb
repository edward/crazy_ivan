require 'fileutils'
require 'crazy_ivan/report_assembler'
require 'crazy_ivan/test_runner'
require 'crazy_ivan/html_asset_crush'
require 'crazy_ivan/version'
require 'crazy_ivan/vendor/json'

module CrazyIvan
  def self.setup
    Dir['*'].each do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('.ci')

        Dir.chdir('.ci') do
          File.open('version', 'w+') do |f|
            f.puts "#!/usr/bin/env ruby"
            f.puts
            f.puts "# This script grabs a unique hash from your version control system"
            f.puts "#"
            f.puts "# If you're not able to use a VCS, this script could just generate a timestamp."
            f.puts
            f.puts "puts `git show`[/^commit (.+)$/, 1]"
          end
          
          File.open('update', 'w+') do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts
            f.puts "# This script updates your code"
            f.puts "#"
            f.puts "# If you can’t use a version control system, this script could just do some"
            f.puts "# some basic copying commands."
            f.puts
            f.puts "git pull"
          end

          File.open('test', 'w+') do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts
            f.puts "# This script runs your testing suite. For a typical Ruby project running"
            f.puts "# test-unit this is probably all you need."
            f.puts
            f.puts "rake"
          end

          File.chmod 0755, 'update', 'version', 'test'
        end

        puts
        puts "Created #{dir}/.ci/update"
        puts "        #{' ' * (dir + "/.ci").size}/version"
        puts "        #{' ' * (dir + "/.ci").size}/test"
        puts
        puts "Take a look at those 3 scripts to make sure "
        puts "they do the right thing for each case."
        puts
      end
    end
  end

  def self.generate_test_reports_in(output_directory)
    FileUtils.mkdir_p(output_directory)
    Dir['*'].each do |dir|
      if File.directory?(dir)
        report = ReportAssembler.new(output_directory)
        report.test_results << TestRunner.new(dir).invoke
        report.generate
      else
        STDERR.puts "Expected a directory to put the test results in (and didn't get one)."
      end
    end
  end
end