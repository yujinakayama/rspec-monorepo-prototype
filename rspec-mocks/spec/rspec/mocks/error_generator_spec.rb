require "spec_helper"

module RSpec
  module Mocks
    RSpec.describe ErrorGenerator do
      def unexpected_failure_message_for(object_description)
        /received unexpected message :bees with \(#{object_description}\)/
      end

      describe "formatting arguments" do
        context "on non-matcher objects that define #description" do
          it "does not use the object's description" do
            o = double(:double, :description => "Friends")
            expect {
              o.bees(o)
            }.to fail_with(unexpected_failure_message_for(o.inspect))
          end
        end

        context "on matcher objects" do
          context "that define description" do
            it "uses the object's description" do
              d = double(:double)
              o = fake_matcher(Object.new)
              expect {
                d.bees(o)
              }.to raise_error(unexpected_failure_message_for(o.description))
            end
          end

          context "that do not define description" do
            it "does not use the object's description" do
              d = double(:double)
              o = Class.new do
                def self.name
                  "RSpec::Mocks::ArgumentMatchers::"
                end
              end.new

              expect(RSpec::Support.is_a_matcher?(o)).to be true

              expect {
                d.bees(o)
              }.to fail_with(unexpected_failure_message_for(o.inspect))
            end
          end
        end
      end
    end
  end
end
