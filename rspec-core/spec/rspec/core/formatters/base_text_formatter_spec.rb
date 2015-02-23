# encoding: utf-8
require 'rspec/core/formatters/base_text_formatter'

RSpec.describe RSpec::Core::Formatters::BaseTextFormatter do
  include FormatterSupport

  context "when closing the formatter", :isolated_directory => true do
    it 'does not close an already closed output stream' do
      output_to_close = File.new("./output_to_close", "w")
      formatter = described_class.new(output_to_close)
      output_to_close.close

      expect { formatter.close(RSpec::Core::Notifications::NullNotification) }.not_to raise_error
    end
  end

  describe "#dump_summary" do
    it "with 0s outputs pluralized (excluding pending)" do
      send_notification :dump_summary, summary_notification(0, [], [], [], 0)
      expect(output.string).to match("0 examples, 0 failures")
    end

    it "with 1s outputs singular (including pending)" do
      send_notification :dump_summary, summary_notification(0, examples(1), examples(1), examples(1), 0)
      expect(output.string).to match("1 example, 1 failure, 1 pending")
    end

    it "with 2s outputs pluralized (including pending)" do
      send_notification :dump_summary, summary_notification(2, examples(2), examples(2), examples(2), 0)
      expect(output.string).to match("2 examples, 2 failures, 2 pending")
    end

    describe "rerun command for failed examples" do
      it "uses the location to identify the example" do
        line = __LINE__ + 2
        example_group = RSpec.describe("example group") do
          it("fails") { fail }
        end

        expect(output_from_running example_group).to include("rspec #{RSpec::Core::Metadata::relative_path("#{__FILE__}:#{line}")} # example group fails")
      end

      context "for an example defined in an file required by the user rather than loaded by rspec" do
        it "looks through ancestor metadata to find a workable re-run command" do
          line = __LINE__ + 1
          example_group = RSpec.describe("example group") do
            # Using eval in order to make it think this got defined in an external file.
            instance_eval "it('fails') { fail }", "some/external/file.rb", 1
          end

          expect(output_from_running example_group).to include("rspec #{RSpec::Core::Metadata::relative_path("#{__FILE__}:#{line}")} # example group fails")
        end
      end

      context "for an example that is not uniquely identified by the location" do
        it "uses the id instead" do
          example_group = RSpec.describe("example group") do
            1.upto(2) do |i|
              it("compares #{i} against 2") { expect(i).to eq(2) }
            end
          end

          expect(output_from_running example_group).to include("rspec #{RSpec::Core::Metadata::relative_path("#{__FILE__}[1:1]")} # example group compares 1 against 2")
        end
      end

      def output_from_running(example_group)
        allow(RSpec.configuration).to receive(:loaded_spec_files) { RSpec::Core::Set.new([File.expand_path(__FILE__)]) }
        example_group.run(reporter)
        examples = example_group.examples
        failed   = examples.select { |e| e.execution_result.status == :failed }
        send_notification :dump_summary, summary_notification(1, examples, failed, [], 0)
        output.string
      end
    end
  end

  describe "#dump_failures" do
    let(:group) { RSpec.describe("group name") }

    before { allow(RSpec.configuration).to receive(:color_enabled?) { false } }

    def run_all_and_dump_failures
      group.run(reporter)
      send_notification :dump_failures, failed_examples_notification
    end

    it "preserves formatting" do
      group.example("example name") { expect("this").to eq("that") }

      run_all_and_dump_failures

      expect(output.string).to match(/group name example name/m)
      expect(output.string).to match(/(\s+)expected: \"that\"\n\1     got: \"this\"/m)
    end

    context "with an exception without a message" do
      it "does not throw NoMethodError" do
        exception_without_message = Exception.new()
        allow(exception_without_message).to receive(:message) { nil }
        group.example("example name") { raise exception_without_message }
        expect { run_all_and_dump_failures }.not_to raise_error
      end

      it "preserves ancestry" do
        example = group.example("example name") { raise "something" }
        run_all_and_dump_failures
        expect(example.example_group.parent_groups.size).to eq 1
      end
    end

    context "with an exception that has an exception instance as its message" do
      it "does not raise NoMethodError" do
        gonzo_exception = RuntimeError.new
        allow(gonzo_exception).to receive(:message) { gonzo_exception }
        group.example("example name") { raise gonzo_exception }
        expect { run_all_and_dump_failures }.not_to raise_error
      end
    end

    context "with an instance of an anonymous exception class" do
      it "substitutes '(anonymous error class)' for the missing class name" do
        exception = Class.new(StandardError).new
        group.example("example name") { raise exception }
        run_all_and_dump_failures
        expect(output.string).to include('(anonymous error class)')
      end
    end

    context "with an exception class other than RSpec" do
      it "does not show the error class" do
        group.example("example name") { raise NameError.new('foo') }
        run_all_and_dump_failures
        expect(output.string).to match(/NameError/m)
      end
    end

    if String.method_defined?(:encoding)
      context "with an exception that has a differently encoded message" do
        it "runs without encountering an encoding exception" do
          group.example("Mixing encodings, e.g. UTF-8: © and Binary") { raise "Error: \xC2\xA9".force_encoding("ASCII-8BIT") }
          run_all_and_dump_failures
          expect(output.string).to match(/RuntimeError:\n\s+Error: \?\?/m) # ?? because the characters dont encode properly
        end
      end
    end

    context "with a failed expectation (rspec-expectations)" do
      it "does not show the error class" do
        group.example("example name") { expect("this").to eq("that") }
        run_all_and_dump_failures
        expect(output.string).not_to match(/RSpec/m)
      end
    end

    context "with a failed message expectation (rspec-mocks)" do
      it "does not show the error class" do
        group.example("example name") { expect("this").to receive("that") }
        run_all_and_dump_failures
        expect(output.string).not_to match(/RSpec/m)
      end
    end

    %w[ include_examples it_should_behave_like ].each do |inclusion_method|
      context "for #shared_examples included using #{inclusion_method}" do
        it 'outputs the name and location' do
          group.shared_examples 'foo bar' do
            it("example name") { expect("this").to eq("that") }
          end

          line = __LINE__.next
          group.__send__(inclusion_method, 'foo bar')

          run_all_and_dump_failures

          expect(output.string.lines).to include(a_string_ending_with(
            'Shared Example Group: "foo bar" called from ' +
              "#{RSpec::Core::Metadata.relative_path(__FILE__)}:#{line}\n"
          ))
        end

        context 'that contains nested example groups' do
          it 'outputs the name and location' do
            group.shared_examples 'foo bar' do
              describe 'nested group' do
                it("example name") { expect("this").to eq("that") }
              end
            end

            line = __LINE__.next
            group.__send__(inclusion_method, 'foo bar')

            run_all_and_dump_failures

            expect(output.string.lines).to include(a_string_ending_with(
              'Shared Example Group: "foo bar" called from ' +
                "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}\n"
            ))
          end
        end

        context "that contains shared group nesting" do
          it 'includes each inclusion location in the output' do
            group.shared_examples "inner" do
              example { expect(1).to eq(2) }
            end

            inner_line = __LINE__ + 2
            group.shared_examples "outer" do
              __send__(inclusion_method, "inner")
            end

            outer_line = __LINE__ + 1
            group.__send__(inclusion_method, 'outer')

            run_all_and_dump_failures

            expect(output.string.lines.grep(/Shared Example Group/)).to match [
              a_string_ending_with(
                'Shared Example Group: "inner" called from ' +
                  "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{inner_line}\n"
              ),
              a_string_ending_with(
                'Shared Example Group: "outer" called from ' +
                  "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{outer_line}\n"
              ),
            ]
          end
        end
      end
    end
  end

  describe "custom_colors" do
    it "uses the custom success color" do
      RSpec.configure do |config|
        config.color = true
        config.tty = true
        config.success_color = :cyan
      end
      send_notification :dump_summary, summary_notification(0, examples(1), [], [], 0)
      expect(output.string).to include("\e[36m")
    end
  end
end
