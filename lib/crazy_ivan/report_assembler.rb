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
    
    s
  end
  
  def update_project(result)
    FileUtils.mkdir_p(result.project_name)
    Dir.chdir(result.project_name) do
      filename = filename_from_version(result.version_output)
      File.open("#{filename}.json", 'w+') do |f|
        f.puts({
                 "version" => [result.version_error, result.version_output].join,
                 "timestamp" => result.timestamp,
                 "update" => result.update_output,
                 "update_error" => result.update_error,
                 "test" => result.test_output,
                 "test_error" => result.test_error
               }.to_json)
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
    projects = @test_results.map {|r| "#{r.project_name}"}
    
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