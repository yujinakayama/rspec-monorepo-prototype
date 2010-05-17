require 'spec_helper'

describe RSpec::Expectations, "#fail_with with no diff" do
  before(:each) do
    @old_differ = RSpec::Expectations.differ
    RSpec::Expectations.differ = nil
  end
  
  it "should handle just a message" do
    lambda {
      RSpec::Expectations.fail_with "the message"
    }.should fail_with("the message")
  end
  
  after(:each) do
    RSpec::Expectations.differ = @old_differ
  end
end

describe RSpec::Expectations, "#fail_with with Array" do
  before(:each) do
    RSpec::Core.stub!(:warn)
  end
end

describe RSpec::Expectations, "#fail_with with diff" do
  before(:each) do
    @old_differ = RSpec::Expectations.differ
    @differ = mock("differ")
    RSpec::Expectations.differ = @differ
  end
  
  it "should not call differ if no expected/actual" do
    lambda {
      RSpec::Expectations.fail_with "the message"
    }.should fail_with("the message")
  end
  
  it "should call differ if expected/actual are presented separately" do
    @differ.should_receive(:diff_as_string).and_return("diff")
    lambda {
      RSpec::Expectations.fail_with "the message", "expected", "actual"
    }.should fail_with("the message\nDiff:diff")
  end
  
  it "should call differ if expected/actual are not strings" do
    @differ.should_receive(:diff_as_object).and_return("diff")
    lambda {
      RSpec::Expectations.fail_with "the message", :expected, :actual
    }.should fail_with("the message\nDiff:diff")
  end
  
  it "should not call differ if expected or actual are procs" do
    @differ.should_not_receive(:diff_as_string)
    @differ.should_not_receive(:diff_as_object)
    lambda {
      RSpec::Expectations.fail_with "the message", lambda {}, lambda {}
    }.should fail_with("the message")
  end

  after(:each) do
    RSpec::Expectations.differ = @old_differ
  end
end

describe RSpec::Expectations, "#fail_with with a nil message" do
  before(:each) do
    @old_differ = RSpec::Expectations.differ
    RSpec::Expectations.differ = nil
  end

  it "should handle just a message" do
    lambda {
      RSpec::Expectations.fail_with nil
    }.should raise_error(ArgumentError, /Failure message is nil\. Does your matcher define the appropriate failure_message_for_\* method to return a string\?/)
  end

  after(:each) do
    RSpec::Expectations.differ = @old_differ
  end
end
