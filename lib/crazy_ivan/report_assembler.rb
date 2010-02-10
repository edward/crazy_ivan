class ReportAssembler
  MAXIMUM_RECENTS = 10
  TEMPLATES_PATH = File.expand_path(File.dirname(__FILE__)) + '/templates'
  
  attr_accessor :runners
  
  def initialize(projects_directory, output_directory)
    @runners = []
    @projects = {}
    @projects_directory = projects_directory
    @output_directory = File.expand_path(output_directory, projects_directory)
  end
  
  def generate
    Dir.chdir(@projects_directory) do
      Dir['*'].each do |dir|
        if File.directory?(dir)
          runners << TestRunner.new(File.join(@projects_directory, dir), self)
        end
      end
    end
    
    Dir.chdir(@output_directory) do
      # Write out the index.html file
      update_index
      
      # Write out the projects.json file and the reports.json in each
      update_projects
      init_project_reports
      
      get_project_reports
      
      runners.each do |runner|
        # REFACTOR to run this block in multiple threads to have multi-project testing
        
        # Write the first version of the report with just the start time to currently_building.json
        runner.start!
        update_currently_building(runner)
        
        # Update the report in currently_building.json with the update output and error
        runner.update!
        update_currently_building(runner)
        
        # Update the report in currently_building.json with the version output and error
        runner.version!
        update_currently_building(runner)
        
        if already_tested?(runner)
          Syslog.debug("Already tested #{runner.project_name} version #{runner.results[:version][:output]} - skipping test")
        else
          # update_project will be called from within the runner to stream the test output
          runner.test!
          update_project(runner)
        end
        flush_build_progress(runner)
      end
    end
  end
  
  def update_index
    FileUtils.cp(File.expand_path("index.html", TEMPLATES_PATH), 'index.html')
    FileUtils.mkdir_p('javascript')
    FileUtils.cp(File.expand_path("date.js", File.join(TEMPLATES_PATH, 'javascript')), 'javascript/date.js')
  end
    
  def update_projects
    projects = @runners.map {|r| r.project_name }
    
    File.open('projects.json', 'w+') do |f|
      f.print({"projects" => projects}.to_json)
    end
  end
  
  def init_project_reports
    projects = @runners.map {|r| r.project_name }
    
    projects.each do |project_name|
      FileUtils.mkdir_p(project_name)
      Dir.chdir(project_name) do
        if !File.exists?('reports.json')
          File.open('reports.json', 'w+') do |f|
            f.puts [].to_json
          end
        end
      end
    end
  end
  
  def get_project_reports
    projects = @runners.map {|r| r.project_name }
    
    Dir.chdir(@output_directory) do
      projects.each do |project_name|
        reports = JSON.parse(File.read(File.expand_path('reports.json', project_name)))
        @projects[project_name] = reports
      end
    end
  end
  
  def update_currently_building(runner)
    project_path = File.expand_path(runner.project_name, @output_directory)
    Dir.chdir(project_path) do
      File.open('currently_building.json', 'w+') do |f|
        f.puts runner.results.to_json
      end
    end
  end
  
  def already_tested?(runner)
    project_path = File.join(@output_directory, runner.project_name)
    
    Dir.chdir(project_path) do
      version = runner.results[:version][:output]
      tested_versions = @projects[runner.project_name].map {|r| r['version']['output'] }
      tested_versions.include?(version)
    end
  end
  
  def update_project(runner)
    project_path = File.expand_path(runner.project_name, @output_directory)
    
    @projects[runner.project_name] << runner.results
    cull_old_reports(runner.project_name)
    
    Dir.chdir(project_path) do
      File.open("reports.json", 'w+') do |f|
        f.puts @projects[runner.project_name].to_json
      end
    end
  end
  
  def cull_old_reports(project_name)
    @projects[project_name].shift if @projects[project_name].size > MAXIMUM_RECENTS
  end
  
  def flush_build_progress(runner)
    project_results_path = File.join(@output_directory, runner.project_name)
    
    Dir.chdir(project_results_path) do
      File.open("currently_building.json", 'w+') do |f|
        f.puts({}.to_json)
      end
    end
  end
end