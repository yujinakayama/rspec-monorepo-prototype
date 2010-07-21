require 'spec_helper'
require 'stringio'

describe RSpec::Core::Formatters::ProgressFormatter do

   before do
     @output = StringIO.new
     @formatter = RSpec::Core::Formatters::ProgressFormatter.new(@output)
     @formatter.start(2)
     @formatter.stub!(:color_enabled?).and_return(false)
   end

   it "should produce line break on start dump" do
     @formatter.start_dump
     @output.string.should == "\n"
   end

   it "should produce standard summary without pending when pending has a 0 count" do
     pending
     @formatter.start_dump
     @formatter.dump_summary
     @output.string.should =~ /2 examples/i
   end

   it "should push nothing on start" do
     @formatter.start(4)
     @output.string.should == ""
   end

end
