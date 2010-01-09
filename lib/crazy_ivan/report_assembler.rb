class ReportAssembler
  MAXIMUM_RECENTS = 10
  ROOT_PATH = File.expand_path(File.dirname(__FILE__))
  TEMPLATES_PATH = File.join(ROOT_PATH, *%w[.. .. templates])
  
  attr_accessor :test_results
  
  def initialize(output_directory)
    @test_results = []
    @output_directory = output_directory
  end
  
  def generate_for(runner)
    # Write the first version of the report with just the start time to currently_building.json
    runner.start!
    update_project(runner)
    
    # Update the report in currently_building.json with the update output and error
    runner.update!
    update_project(runner)
    
    # Update the report in currently_building.json with the version output and error
    runner.version!
    update_project(runner)
    
    # Empty the currently_building.json and add to recents.json this new report with the test output and error
    runner.test!
    update_project(runner)
  end
  
  def filename_from_version(string)
    s = string[0..240]
    
    if Dir["#{s}*.json"].size > 0
      s += "-#{Dir["#{s}*.json"].size}"
    end
    
    return s
  end
  
  def nullify_successful_exit_status_for_json_templates(results)
    results[:version][:exit_status] = nil if results[:version][:exit_status] == '0'
    results[:update][:exit_status] = nil if results[:version][:exit_status] == '0'
    results[:test][:exit_status] = nil if results[:version][:exit_status] == '0'
    
    return results
  end
  
  def flush_build_progress
    File.open("currently_building.json", 'w+') do |f|
      f.puts({}.to_json)
    end
  end
  
  def update_project(runner)
    FileUtils.mkdir_p(runner.project_name)
    Dir.chdir(runner.project_name) do
      
      filename = ''
      
      if runner.still_building?
        filename = 'currently_building'
      else
        if runner.results[:version][:exit_status] == '0'
          filename = filename_from_version(runner.results[:version][:output])
        else
          filename = filename_from_version(runner.results[:version][:error])
        end
      end
      
      File.open("#{filename}.json", 'w+') do |f|
        f.puts(nullify_successful_exit_status_for_json_templates(runner.results).to_json)
      end
      
      if runner.finished?
        flush_build_progress
        update_recent(runner.results, filename)
      end
    end
  end
  
  def update_recent(result, filename)
    recent_versions_json = File.open('recent.json', File::RDWR | File::CREAT).read
    
    recent_versions = []
    
    if !recent_versions_json.empty?
      recent_versions = JSON.parse(recent_versions_json)["recent_versions"]
    end
    
    recent_versions << filename
    recent_versions.shift if recent_versions.size > MAXIMUM_RECENTS
    
    File.open('recent.json', 'w+') do |f|
      f.print({"recent_versions" => recent_versions}.to_json)
    end
  end
  
  def update_projects
    projects = @test_results.map {|r| "#{r[:project_name]}"}
    
    File.open('projects.json', 'w+') do |f|
      f.print({"projects" => projects}.to_json)
    end
  end
  
  def update_index
    index_template = HtmlAssetCrush.crush(File.join(TEMPLATES_PATH, "index.html"))
    
    File.open('index.html', 'w+') do |f|
      f.print index_template
    end
  end
end