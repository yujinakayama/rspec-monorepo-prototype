class Bar; end
class Foo; end

module RSpec::Core

  RSpec.describe RSpec::Core::World do
    let(:configuration) { RSpec::Core::Configuration.new }
    let(:world) { RSpec::Core::World.new(configuration) }

    describe '#reset' do
      it 'clears #example_groups' do
        world.example_groups << :example_group
        world.reset
        expect(world.example_groups).to be_empty
      end
    end

    describe "#example_groups" do
      it "contains all registered example groups" do
        example_group = RSpec.describe("group") {}
        world.register(example_group)
        expect(world.example_groups).to include(example_group)
      end
    end

    describe "#all_examples" do
      it "contains all examples from all levels of nesting" do
        RSpec.describe do
          example("ex1")

          context "nested" do
            example("ex2")

            context "nested" do
              example("ex3")
              example("ex4")
            end
          end

          example("ex5")
        end

        RSpec.describe do
          example("ex6")
        end

        expect(RSpec.world.all_examples.map(&:description)).to match_array(%w[
          ex1 ex2 ex3 ex4 ex5 ex6
        ])
      end
    end

    describe "#preceding_declaration_line (again)" do
      let(:group) do
        RSpec.describe("group") do

          example("example") {}

        end
      end

      let(:second_group) do
        RSpec.describe("second_group") do

          example("second_example") {}

        end
      end

      let(:group_declaration_line) { group.metadata[:line_number] }
      let(:example_declaration_line) { group_declaration_line + 2 }

      context "with one example" do
        before { world.register(group) }

        it "returns nil if no example or group precedes the line" do
          expect(world.preceding_declaration_line(group_declaration_line - 1)).to be_nil
        end

        it "returns the argument line number if a group starts on that line" do
          expect(world.preceding_declaration_line(group_declaration_line)).to eq(group_declaration_line)
        end

        it "returns the argument line number if an example starts on that line" do
          expect(world.preceding_declaration_line(example_declaration_line)).to eq(example_declaration_line)
        end

        it "returns line number of a group that immediately precedes the argument line" do
          expect(world.preceding_declaration_line(group_declaration_line + 1)).to eq(group_declaration_line)
        end

        it "returns line number of an example that immediately precedes the argument line" do
          expect(world.preceding_declaration_line(example_declaration_line + 1)).to eq(example_declaration_line)
        end
      end

      context "with two exaples and the second example is registre first" do
        let(:second_group_declaration_line) { second_group.metadata[:line_number] }

        before do
          world.register(second_group)
          world.register(group)
        end

        it 'return line number of group if a group start on that line' do
          expect(world.preceding_declaration_line(second_group_declaration_line)).to eq(second_group_declaration_line)
        end
      end
    end

    describe "#announce_filters" do
      let(:reporter) { double('reporter').as_null_object }
      before { allow(world).to receive(:reporter) { reporter } }

      context "with no examples" do
        before { allow(world).to receive(:example_count) { 0 } }

        context "with no filters" do
          it "announces" do
            expect(reporter).to receive(:message).
              with("No examples found.")
            world.announce_filters
          end
        end

        context "with an inclusion filter" do
          it "announces" do
            configuration.filter_run_including :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an inclusion filter and run_all_when_everything_filtered" do
          it "announces" do
            allow(configuration).to receive(:run_all_when_everything_filtered?) { true }
            configuration.filter_run_including :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end

        context "with an exclusion filter" do
          it "announces" do
            configuration.filter_run_excluding :foo => 'bar'
            expect(reporter).to receive(:message).
              with(/All examples were filtered out/)
            world.announce_filters
          end
        end
      end

      context "with examples" do
        before { allow(world).to receive(:example_count) { 1 } }

        context "with no filters" do
          it "does not announce" do
            expect(reporter).not_to receive(:message)
            world.announce_filters
          end
        end
      end
    end
  end
end
