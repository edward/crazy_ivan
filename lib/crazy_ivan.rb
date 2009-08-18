require "report_assembler"
require "test_runner"

module CrazyIvan
  def generate_test_reports_in(output_directory)
    Dir['*'].each do |dir|
      report = ReportAssembler.new(output_directory)
  
      if File.directory?(dir)
        report.test_results << TestRunner.new(dir).invoke
      end
  
      report.generate
    end
  end
end