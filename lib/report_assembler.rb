class ReportAssembler
  MAXIMUM_RECENTS = 10
  
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
  
  def update_project(result)
    FileUtils.mkdir_p(result.project_name)
    Dir.chdir(result.project_name) do
      File.open("#{result.version_output}.json", 'w+') do |f|
        f.puts <<-PROJECT_JSON_RUBY
        {
          project: '#{result.project_name}',
          version: '#{result.version_output}',
          update: '#{result.update_output}',
          update_error: '#{result.update_error}',
          test: '#{result.test_output}',
          test_error: '#{result.test_error}'
        }
        PROJECT_JSON_RUBY
      end
      
      update_recent(result)
    end
  end
  
  def update_recent(result)
    recent_versions = eval(File.open('recent.json', File::RDWR|File::CREAT).read) || []
    recent_versions << result.version_output
    recent_versions.shift if recent_versions.size > MAXIMUM_RECENTS
    
    File.open('recent.json', "w+") do |f|
      f.print "[#{recent_versions.map {|v| "'#{v}'"}.join(', ')}]"
    end
  end
  
  def update_projects
    projects = @test_results.map {|r| "'#{r.project_name}'"}
    
    File.open('projects.json', 'w+') do |f|
      f.print "[#{projects.join(', ')}]"
    end
  end
  
  def update_index
    # WORKING HERE
    raise "Please implement ReportAssembler#update_index"
  end
end