require "spec_helper"

module RSpec
  module Core
    module Ordering
      describe Identity do
        it "does not affect the ordering of the items" do
          expect(Identity.new.order([1, 2, 3])).to eq([1, 2, 3])
        end
      end

      describe Random do
        before { allow(Kernel).to receive(:srand).and_call_original }

        def order_of(input, seed)
          Kernel.srand(seed)
          input.shuffle
        end

        let(:configuration) { RSpec::Core::Configuration.new }

        it 'shuffles the items randomly' do
          configuration.seed = 900

          expected = order_of([1, 2, 3, 4], 900)

          strategy = Random.new(configuration)
          expect(strategy.order([1, 2, 3, 4])).to eq(expected)
        end

        it 'seeds the random number generator' do
          expect(Kernel).to receive(:srand).with(1234).once

          configuration.seed = 1234

          strategy = Random.new(configuration)
          strategy.order([1, 2, 3, 4])
        end

        it 'resets random number generation' do
          expect(Kernel).to receive(:srand).with(no_args)

          strategy = Random.new(configuration)
          strategy.order([])
        end
      end

      describe Custom do
        it 'uses the block to order the list' do
          strategy = Custom.new(proc { |list| list.reverse })

          expect(strategy.order([1, 2, 3, 4])).to eq([4, 3, 2, 1])
        end
      end

      describe Registry do
        let(:configuration) { Configuration.new }
        subject(:registry) { Registry.new(configuration) }

        describe "#used_random_seed?" do
          it 'returns false if the random orderer has not been used' do
            expect(registry.used_random_seed?).to be false
          end

          it 'returns false if the random orderer has been fetched but not used' do
            expect(registry[:random]).to be_a(Random)
            expect(registry.used_random_seed?).to be false
          end

          it 'returns true if the random orderer has been used' do
            registry[:random].order([1, 2])
            expect(registry.used_random_seed?).to be true
          end
        end

        describe "#[]" do
          it "gives the default ordering when given nil" do
            expect(subject[nil]).to be_an_instance_of(Identity)
          end

          it "gives a callable ordering when called with a callable" do
            expect(subject[proc { :hi }]).to be_a_kind_of(Custom)
          end

          it "gives the registered ordering when called with a symbol" do
            ordering = Object.new
            subject.register(:falcon, ordering)

            expect(subject[:falcon]).to be ordering
          end

          it "gives me the global one when I call it with an unknown symbol" do
            expect(subject[:falcon]).to be_an_instance_of(Identity)
          end
        end
      end
    end
  end
end

