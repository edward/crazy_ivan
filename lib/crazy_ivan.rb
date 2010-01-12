require 'syslog'
require 'fileutils'
require 'crazy_ivan/report_assembler'
require 'crazy_ivan/test_runner'
require 'crazy_ivan/html_asset_crush'
require 'crazy_ivan/version'
require 'crazy_ivan/vendor/json'
require 'crazy_ivan/vendor/open4'
require 'crazy_ivan/vendor/tmpdir'

module CrazyIvan
  # VERSION = '1.0.0'
  
  def self.setup
    puts
    puts "Preparing per-project continuous integration configuration scripts"
    puts
    
    Dir['*'].each do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('.ci')

        Dir.chdir('.ci') do
          puts "        #{dir}/.ci"
          if File.exists?('version')
            puts "      #{' ' * (dir + "/.ci").size}/version already exists - skipping"
          else
            File.open('version', 'w+') do |f|
              f.puts "#!/usr/bin/env ruby"
              f.puts
              f.puts "# This script grabs a unique version name from your version control system"
              f.puts "#"
              f.puts "# If you're not able to use a VCS, this script could just generate a timestamp."
              f.puts
              f.puts "puts `git show`[/^commit (.+)$/, 1]"
            end
            puts "      #{' ' * (dir + "/.ci").size}/version -- created"
          end
          
          if File.exists?('update')
            puts "      #{' ' * (dir + "/.ci").size}/update already exists - skipping"
          else
            File.open('update', 'w+') do |f|
              f.puts "#!/usr/bin/env bash"
              f.puts
              f.puts "# This script updates your code"
              f.puts "#"
              f.puts "# If you can't use a version control system, this script could just do some"
              f.puts "# some basic copying commands."
              f.puts
              f.puts "git pull"
            end
            puts "      #{' ' * (dir + "/.ci").size}/update -- created"
          end

          if File.exists?('test')
            puts "        #{' ' * (dir + "/.ci").size}/test already exists -- skipping"
          else
            File.open('test', 'w+') do |f|
              f.puts "#!/usr/bin/env bash"
              f.puts
              f.puts "# This script runs your testing suite. For a typical Ruby project running"
              f.puts "# test-unit this is probably all you need."
              f.puts
              f.puts "rake"
            end
            puts "      #{' ' * (dir + "/.ci").size}/test -- created"
          end
          
          if File.exists?('conclusion')
            puts "      #{' ' * (dir + "/.ci").size}/conclusion already exists -- skipping"
          else
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
            puts "      #{' ' * (dir + "/.ci").size}/conclusion -- created"
          end
          puts

          File.chmod 0755, 'update', 'version', 'test', 'conclusion'
        end
      end
    end
    
    puts "Take a look at those 4 scripts to make sure they each do the right thing."
    puts
    puts "When you're ready, run crazy_ivan manually from the projects directory (here):"
    puts
    puts "  crazy_ivan /path/to/directory/your/reports/go"
    puts
    puts "then look at index.html in that path to confirm that everything is ok."
    puts
    puts "If things look good, then set up a cron job or other script to run"
    puts "crazy_ivan on a periodic basis."
    puts
    puts "To setup a cron job to run crazy_ivan every 15 minutes, do this:"
    puts "  $ echo \"0,15,30,45 * * * * cd /var/continuous-integration; crazy_ivan /var/www/ci\" > ci.cron"
    puts "  $ crontab ci.cron"
    puts
    puts
  end

  def self.generate_test_reports_in(output_directory)
    Syslog.open('crazy_ivan', Syslog::LOG_PID | Syslog::LOG_CONS)
    FileUtils.mkdir_p(output_directory)
    
    report = ReportAssembler.new(Dir.pwd, output_directory)
    report.generate
    
    msg = "Generated test reports for #{report.runners.size} projects"
    Syslog.info(msg)
    puts msg
    # REFACTOR to use a logger that spits out to both STDOUT and Syslog
  ensure
    Syslog.close
  end
end