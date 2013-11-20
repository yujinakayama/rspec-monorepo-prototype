module RSpec
  module Mocks

    # ArgumentMatchers are placeholders that you can include in message
    # expectations to match arguments against a broader check than simple
    # equality.
    #
    # With the exception of `any_args` and `no_args`, they all match against
    # the arg in same position in the argument list.
    #
    # @see ArgumentListMatcher
    module ArgumentMatchers
      # Matches any args at all. Supports a more explicit variation of
      # `object.should_receive(:message)`
      #
      # @example
      #
      #   object.should_receive(:message).with(any_args)
      def any_args
        AnyArgsMatcher.new
      end

      # Matches any argument at all.
      #
      # @example
      #
      #   object.should_receive(:message).with(anything)
      def anything
        AnyArgMatcher.new
      end

      # Matches no arguments.
      #
      # @example
      #
      #   object.should_receive(:message).with(no_args)
      def no_args
        NoArgsMatcher.new
      end

      # Matches if the actual argument responds to the specified messages.
      #
      # @example
      #
      #   object.should_receive(:message).with(duck_type(:hello))
      #   object.should_receive(:message).with(duck_type(:hello, :goodbye))
      def duck_type(*args)
        DuckTypeMatcher.new(*args)
      end

      # Matches a boolean value.
      #
      # @example
      #
      #   object.should_receive(:message).with(boolean())
      def boolean
        BooleanMatcher.new
      end

      # Matches a hash that includes the specified key(s) or key/value pairs.
      # Ignores any additional keys.
      #
      # @example
      #
      #   object.should_receive(:message).with(hash_including(:key => val))
      #   object.should_receive(:message).with(hash_including(:key))
      #   object.should_receive(:message).with(hash_including(:key, :key2 => val2))
      def hash_including(*args)
        HashIncludingMatcher.new(ArgumentMatchers.anythingize_lonely_keys(*args))
      end

      # Matches an array that includes the specified items at least once.
      # Ignores duplicates and additional values
      #
      # @example
      #
      #   object.should_receive(:message).with(array_including(1,2,3))
      #   object.should_receive(:message).with(array_including([1,2,3]))
      def array_including(*args)
        actually_an_array = Array === args.first && args.count == 1 ? args.first : args
        ArrayIncludingMatcher.new(actually_an_array)
      end

      # Matches a hash that doesn't include the specified key(s) or key/value.
      #
      # @example
      #
      #   object.should_receive(:message).with(hash_excluding(:key => val))
      #   object.should_receive(:message).with(hash_excluding(:key))
      #   object.should_receive(:message).with(hash_excluding(:key, :key2 => :val2))
      def hash_excluding(*args)
        HashExcludingMatcher.new(ArgumentMatchers.anythingize_lonely_keys(*args))
      end

      alias_method :hash_not_including, :hash_excluding

      # Matches if `arg.instance_of?(klass)`
      #
      # @example
      #
      #   object.should_receive(:message).with(instance_of(Thing))
      def instance_of(klass)
        InstanceOf.new(klass)
      end

      alias_method :an_instance_of, :instance_of

      # Matches if `arg.kind_of?(klass)`
      # @example
      #
      #   object.should_receive(:message).with(kind_of(Thing))
      def kind_of(klass)
        klass
      end

      alias_method :a_kind_of, :kind_of

      # @api private
      def self.anythingize_lonely_keys(*args)
        hash = args.last.class == Hash ? args.delete_at(-1) : {}
        args.each { | arg | hash[arg] = AnyArgMatcher.new }
        hash
      end

      # @api private
      # Implements our matching semantics for two arbitrary values.
      def self.values_match?(expected, actual)
        # `===` provides the main matching semantics we want, but
        # has some slight gotchas:
        #
        # * `Fixnum === Fixnum` returns false.
        # * `/abc/ === /abc/`   returns false.
        #
        # So, for cases like these, we check `==` as well as a fallback.
        expected === actual || actual == expected
      end

      # @api private
      class AnyArgsMatcher
        def description
          "any args"
        end
      end

      # @api private
      class AnyArgMatcher
        def ===(other)
          true
        end
      end

      # @api private
      class NoArgsMatcher
        def description
          "no args"
        end
      end

      # @api private
      class BooleanMatcher
        def ===(value)
          true == value || false == value
        end
      end

      # @api private
      class BaseHashMatcher
        def initialize(expected)
          @expected = expected
        end

        def ===(predicate, actual)
          @expected.__send__(predicate) do |k, v|
            actual.has_key?(k) && ArgumentMatchers.values_match?(v, actual[k])
          end
        rescue NoMethodError
          false
        end

        def description(name)
          "#{name}(#{@expected.inspect.sub(/^\{/,"").sub(/\}$/,"")})"
        end
      end

      # @api private
      class HashIncludingMatcher < BaseHashMatcher
        def ===(actual)
          super(:all?, actual)
        end

        def description
          super("hash_including")
        end
      end

      # @api private
      class HashExcludingMatcher < BaseHashMatcher
        def ===(actual)
          super(:none?, actual)
        end

        def description
          super("hash_not_including")
        end
      end

      # @api private
      class ArrayIncludingMatcher
        def initialize(expected)
          @expected = expected
        end

        def ===(actual)
          Set.new(actual).superset?(Set.new(@expected))
        end

        def description
          "array_including(#{@expected.join(",")})"
        end
      end

      # @api private
      class DuckTypeMatcher
        def initialize(*methods_to_respond_to)
          @methods_to_respond_to = methods_to_respond_to
        end

        def ===(value)
          @methods_to_respond_to.all? {|message| value.respond_to?(message)}
        end
      end

      # @api private
      class MatcherMatcher
        def initialize(matcher)
          @matcher = matcher
        end

        def ===(value)
          @matcher.matches?(value)
        end
      end

      # @api private
      class InstanceOf
        def initialize(klass)
          @klass = klass
        end

        def ===(actual)
          actual.instance_of?(@klass)
        end
      end

    end
  end
end
