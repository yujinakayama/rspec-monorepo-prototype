require 'spec_helper'

module Rspec
  module Mocks
    describe "mock failure" do
      
      it "should tell you when it receives the right message with the wrong args" do
        m = mock("foo")
        m.should_receive(:bar).with("message")
        lambda {
          m.bar("different message")
        }.should raise_error(Rspec::Mocks::MockExpectationError, %Q{Mock "foo" received :bar with unexpected arguments\n  expected: ("message")\n       got: ("different message")})
        m.rspec_reset # so the example doesn't fail
      end

      pending "should tell you when it receives the right message with the wrong args if you stub the method (fix bug 15719)" do
        # NOTE - for whatever reason, if you use a the block style of pending here,
        # rcov gets unhappy. Don't know why yet.
        m = mock("foo")
        m.stub!(:bar)
        m.should_receive(:bar).with("message")
        lambda {
          m.bar("different message")
        }.should raise_error(Rspec::Mocks::MockExpectationError, %Q{Mock 'foo' expected :bar with ("message") but received it with ("different message")})
        m.rspec_reset # so the example doesn't fail
      end
    end
  end
end
