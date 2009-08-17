class ReportAssembler
  attr_accessor :tests
  
  def initialize(output_directory)
    @test_results = []
    @output_directory = output_directory
  end
  
  def generate
    Dir.chdir(output_directory) do
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
        f.puts <<-RUBY
        {
          project: #{result.project_name},
          version: #{result.version_output},
          setup: '#{result.update_output}',
          setup_errorcode: #{result.setup_errorcode},
          test: '#{result.test_output}',
          test_errorcode: '#{result.test_errorcode}'
        }
        RUBY
      end
      
      update_recent(result)
    end
  end
  
  def update_recent(result)
    # WORKING HERE
    recent_versions = File.open('whatever.json', 'r').read # => 
    
    recent_versions = eval(File.open('recent.json', File::RDWR|File::CREAT).read)
    File.open('recent.json', "w+")
  end
end