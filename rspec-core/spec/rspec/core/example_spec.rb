require 'spec_helper'

describe RSpec::Core::Example, :parent_metadata => 'sample' do
  let(:example_group) do
    RSpec::Core::ExampleGroup.describe('group description')
  end

  let(:example) do
    example_group.example('example description')
  end

  describe "attr readers" do
    it "should have one for the parent example group" do
      example.should respond_to(:example_group)
    end

    it "should have one for it's description" do
      example.should respond_to(:description)
    end

    it "should have one for it's metadata" do
      example.should respond_to(:metadata)
    end

    it "should have one for it's block" do
      example.should respond_to(:example_block)
    end
  end

  describe '#inspect' do
    it "should return 'group description - description'" do
      example.inspect.should == 'group description example description'
    end
  end

  describe '#to_s' do
    it "should return #inspect" do
      example.to_s.should == example.inspect
    end
  end

  describe '#described_class' do
    it "returns the class (if any) of the outermost example group" do
      described_class.should == RSpec::Core::Example
    end
  end

  describe "accessing metadata within a running example" do
    it "should have a reference to itself when running" do
      running_example.description.should == "should have a reference to itself when running"
    end

    it "should be able to access the example group's top level metadata as if it were its own" do
      running_example.example_group.metadata.should include(:parent_metadata => 'sample')
      running_example.metadata.should include(:parent_metadata => 'sample')
    end
  end

  describe "#run" do
    it "runs after(:each) when the example passes" do
      after_run = false
      group = RSpec::Core::ExampleGroup.describe do
        after(:each) { after_run = true }
        example('example') { 1.should == 1 }
      end
      group.run_all
      after_run.should be_true, "expected after(:each) to be run"
    end

    it "runs after(:each) when the example fails" do
      after_run = false
      group = RSpec::Core::ExampleGroup.describe do
        after(:each) { after_run = true }
        example('example') { 1.should == 2 }
      end
      group.run_all
      after_run.should be_true, "expected after(:each) to be run"
    end

    it "runs after(:each) when the example raises an Exception" do
      after_run = false
      group = RSpec::Core::ExampleGroup.describe do
        after(:each) { after_run = true }
        example('example') { raise "this error" } 
      end
      group.run_all
      after_run.should be_true, "expected after(:each) to be run"
    end
  end

  describe "#in_block?" do
    before do
      running_example.should_not be_in_block
    end
    it "is only true during the example (but not before or after)" do
      running_example.should be_in_block
    end
    after do
      running_example.should_not be_in_block
    end
  end
end
