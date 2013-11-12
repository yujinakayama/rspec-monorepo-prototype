require 'rspec/mocks/verifying_message_expecation'
require 'rspec/mocks/method_reference'

module RSpec
  module Mocks

    module VerifyingProxyMethods
      def add_stub(location, method_name, opts={}, &implementation)
        ensure_implemented(method_name)
        super
      end

      def add_simple_stub(method_name, *args)
        ensure_implemented(method_name)
        super
      end

      def add_message_expectation(location, method_name, opts={}, &block)
        ensure_implemented(method_name)
        super
      end

      def ensure_implemented(method_name)
        return unless @doubled_module.defined?

        method_reference[method_name].when_unimplemented do
          @error_generator.raise_unimplemented_error(
            @doubled_module,
            method_name
          )
        end
      end
    end

    # A verifying proxy mostly acts like a normal proxy, except that it
    # contains extra logic to try and determine the validity of any expectation
    # set on it. This includes whether or not methods have been defined and the
    # arity of method calls.
    #
    # In all other ways this behaves like a normal proxy. It only adds the
    # verification behaviour to specific methods then delegates to the parent
    # implementation.
    #
    # These checks are only activated if the doubled class has already been
    # loaded, otherwise they are disabled. This allows for testing in
    # isolation.
    #
    # @api private
    class VerifyingProxy < Proxy
      include VerifyingProxyMethods

      def initialize(object, order_group, name, method_reference_class)
        super(object, order_group)
        @object                 = object
        @doubled_module         = name
        @method_reference_class = method_reference_class

        # A custom method double is required to pass through a way to lookup
        # methods to determine their arity. This is only relevant if the doubled
        # class is loaded.
        @method_doubles = Hash.new do |h, k|
          h[k] = VerifyingMethodDouble.new(@object, k, self, method_reference[k])
        end
      end

      def method_reference
        @method_reference ||= Hash.new do |h, k|
          h[k] = @method_reference_class.new(@doubled_module, k)
        end
      end
    end

    class VerifyingPartialMockProxy < PartialMockProxy
      include VerifyingProxyMethods

      def initialize(object, expectation_ordering)
        super(object, expectation_ordering)
        @doubled_module = DirectObjectReference.new(object)

        # A custom method double is required to pass through a way to lookup
        # methods to determine their arity.
        @method_doubles = Hash.new do |h, k|
          h[k] = VerifyingExistingMethodDouble.new(object, k, self)
        end
      end

      def method_reference
        @method_doubles
      end
    end

    # @api private
    class VerifyingMethodDouble < MethodDouble
      def initialize(object, method_name, proxy, method_reference)
        super(object, method_name, proxy)
        @method_reference = method_reference
      end

      def message_expectation_class
        VerifyingMessageExpectation
      end

      def add_expectation(*arg)
        super.tap { |x| x.method_reference = @method_reference }
      end

      def proxy_method_invoked(obj, *args, &block)
        ensure_arity!(args.length)
        super
      end

    private

      def ensure_arity!(arity)
        @method_reference.when_defined do |method|
          calculator = ArityCalculator.new(method)
          unless calculator.within_range?(arity)
            raise ArgumentError, "wrong number of arguments (#{arity} for #{method.arity})"
          end
        end
      end
    end

    # @api private
    #
    # A VerifyingMethodDouble fetches the method to verify against from the
    # original object, using a MethodReference. This works for pure doubles,
    # but when the original object is itself the one being modified we need to
    # collapse the reference and the method double into a single object so that
    # we can access the original pristine method definition.
    class VerifyingExistingMethodDouble < VerifyingMethodDouble
      def initialize(object, method_name, proxy)
        super(object, method_name, proxy, self)

        @valid_method = object.respond_to?(method_name)

        # Trigger an eager find of the original method since if we find it any
        # later we end up getting a stubbed method with incorrect arity.
        save_original_method!
      end

      def when_defined
        yield original_method
      end

      def when_unimplemented
        yield unless @valid_method
      end
    end
  end
end
