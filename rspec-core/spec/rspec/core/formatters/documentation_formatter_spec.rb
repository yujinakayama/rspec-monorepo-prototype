require "spec_helper"

module RSpec::Core::Formatters
  describe DocumentationFormatter do
    it "numbers the failures" do

      examples = [
        double("example 1",
               :description => "first example",
               :execution_result => {:status => 'failed', :exception_encountered => Exception.new }
              ),
        double("example 2",
               :description => "second example",
               :execution_result => {:status => 'failed', :exception_encountered => Exception.new }
              )
      ]

      output = StringIO.new
      RSpec.configuration.stub(:output) { output }
      RSpec.configuration.stub(:color_enabled?) { false }

      formatter = DocumentationFormatter.new
      
      examples.each {|e| formatter.example_finished(e) }

      output.string.should =~ /first example \(FAILED - 1\)/m
      output.string.should =~ /second example \(FAILED - 2\)/m
    end
  end
end
