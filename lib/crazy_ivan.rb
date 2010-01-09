require 'syslog'
require 'fileutils'
require 'crazy_ivan/report_assembler'
require 'crazy_ivan/test_runner'
require 'crazy_ivan/html_asset_crush'
require 'crazy_ivan/version'
require 'crazy_ivan/vendor/json'
require 'crazy_ivan/vendor/open4'

module CrazyIvan
  def self.setup
    Dir['*'].each do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('.ci')

        Dir.chdir('.ci') do
          File.open('version', 'w+') do |f|
            f.puts "#!/usr/bin/env ruby"
            f.puts
            f.puts "# This script grabs a unique version name from your version control system"
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
          
          File.open('conclusion', 'w+') do |f|
            f.puts "#!/usr/bin/env ruby"
            f.puts
            f.puts "# This script is piped the results of the testing suite run."
            f.puts
            f.puts "# If you're interested in bouncing the message to campfire, "
            f.puts "# emailing, or otherwise sending notifications, this is the place to do it."
            f.puts
            f.puts "# To enable campfire notifications, uncomment the next lines:"
            f.puts "# CAMPFIRE_ROOM_URL = 'http://your-company.campfirenow.com/room/265250'"
            f.puts "# CAMPFIRE_API_KEY = '23b8al234gkj80a3e372133l4k4j34275f80ef8971'"
            f.puts "# CRAZY_IVAN_REPORTS_URL = 'http://ci.your-projects.com'"
            f.puts "# IO.popen(\"test_report2campfire \#{CAMPFIRE_ROOM_URL} \#{CAMPFIRE_API_KEY} \#{CRAZY_IVAN_REPORTS_URL}\", 'w') {|f| f.puts STDIN.read }"
            f.puts
          end

          File.chmod 0755, 'update', 'version', 'test', 'conclusion'
        end

        puts
        puts "Created #{dir}/.ci/update"
        puts "        #{' ' * (dir + "/.ci").size}/version"
        puts "        #{' ' * (dir + "/.ci").size}/test"
        puts "        #{' ' * (dir + "/.ci").size}/conclusion"
        puts
        puts "Take a look at those 4 scripts to make sure they each do the right thing."
        puts
        puts "When you're ready, run"
        puts
        puts "  crazy_ivan /path/to/directory/your/reports/go"
        puts
        puts "then look at index.html in that path to confirm that everything is ok."
        puts
        puts "If things look good, then set up a cron task or other script to run"
        puts "crazy_ivan on a periodic basis."
        puts
      end
    end
  end

  def self.generate_test_reports_in(output_directory)
    Syslog.open('crazy_ivan', Syslog::LOG_PID | Syslog::LOG_CONS)
    FileUtils.mkdir_p(output_directory)
    report = ReportAssembler.new(output_directory)
    
    # REFACTOR to a single pass without this next weird bit where I grab results 
    # because ReportAssembler#update_projects hasn't been refactored yet
    
    # Prep report directories, projects.json and the index
    report.update_index
    Dir['*'].each do |dir|
      if File.directory?(dir)
        runner = TestRunner.new(dir)
        report.test_results << runner.results
      end
    end
    report.update_projects
    report.test_results = []
    
    # Run the tests
    Dir['*'].each do |dir|
      if File.directory?(dir)
        runner = TestRunner.new(dir)
        report.generate_for(runner)
      end
    end
    
    msg = "Generated test reports for #{report.test_results.size} projects"
    Syslog.info(msg)
    puts msg
    # REFACTOR to use a logger that spits out to both STDOUT and Syslog
  ensure
    Syslog.close
  end
end