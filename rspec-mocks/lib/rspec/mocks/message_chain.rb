module RSpec
  module Mocks
    # @private
    class MessageChain
      attr_reader :object, :chain, :block

      def initialize(object, *chain, &blk)
        @object = object
        @chain, @block = format_chain(*chain, &blk)
      end

      # @api private
      def setup_chain
        if chain.length > 1
          if matching_stub = find_matching_stub
            chain.shift
            chain_on(matching_stub.invoke(nil), *chain, &@block)
          elsif matching_expectation = find_matching_expectation
            chain.shift
            chain_on(matching_expectation.invoke_without_incrementing_received_count(nil), *chain, &@block)
          else
            next_in_chain = Double.new
            expectation(object, chain.shift, next_in_chain)
            chain_on(next_in_chain, *chain, &@block)
          end
        else
          ::RSpec::Mocks.allow_message(object, chain.shift, {}, &block)
        end
      end

    private

      def expectation(object, message, returned_object)
        raise NotImplementedError.new
      end

      def chain_on(object, *chain, &block)
        initialize(object, *chain, &block)
        setup_chain
      end

      def format_chain(*chain, &blk)
        if Hash === chain.last
          hash = chain.pop
          hash.each do |k,v|
            chain << k
            blk = lambda { |*_| v }
          end
        end
        return chain.join('.').split('.'), blk
      end

      def find_matching_stub
        ::RSpec::Mocks.proxy_for(object).
          __send__(:find_matching_method_stub, chain.first.to_sym)
      end

      def find_matching_expectation
        ::RSpec::Mocks.proxy_for(object).
          __send__(:find_matching_expectation, chain.first.to_sym)
      end
    end

    # @private
    class ExpectChain < MessageChain
      # @api private
      def self.expect_chain_on(object, *chain, &blk)
        new(object, *chain, &blk).setup_chain
      end

      private

      def expectation(object, message, returned_object)
        ::RSpec::Mocks.expect_message(object, message, {}) { returned_object }
      end
    end

    # @private
    class StubChain < MessageChain
      def self.stub_chain_on(object, *chain, &blk)
        new(object, *chain, &blk).setup_chain
      end

      private

      def expectation(object, message, returned_object)
        ::RSpec::Mocks.allow_message(object, message, {}) { returned_object }
      end
    end
  end
end
