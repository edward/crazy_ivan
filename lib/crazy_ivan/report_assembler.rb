class ReportAssembler
  MAXIMUM_RECENTS = 10
  ROOT_PATH = File.expand_path(File.dirname(__FILE__))
  TEMPLATES_PATH = File.join(ROOT_PATH, *%w[.. .. templates])
  
  attr_accessor :test_results
  
  def initialize(output_directory)
    @test_results = []
    @output_directory = output_directory
  end
  
  def generate
    Dir.chdir(@output_directory) do
      @test_results.each do |result|
        update_project(result)
      end
      
      update_projects
      update_index
    end
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
  
  def update_project(result)
    FileUtils.mkdir_p(result[:project_name])
    Dir.chdir(result[:project_name]) do
      if result[:version][:exit_status] == '0'
        filename = filename_from_version(result[:version][:output])
      else
        filename = filename_from_version(result[:version][:error])
      end
      
      File.open("#{filename}.json", 'w+') do |f|
        f.puts(nullify_successful_exit_status_for_json_templates(result).to_json)
      end
      
      update_recent(result, filename)
    end
  end
  
  def update_recent(result, filename)
    recent_versions_json = File.open('recent.json', File::RDWR|File::CREAT).read
    
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