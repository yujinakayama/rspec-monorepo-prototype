module RSpec
  module Mocks
    # @private
    class InstanceMethodStasher
      def initialize(klass, method)
        @klass = klass
        @method = method

        @method_is_stashed = false
      end

      # @private
      def method_is_stashed?
        @method_is_stashed
      end

      # @private
      def stash
        return if !method_defined_directly_on_klass? || @method_is_stashed

        @klass.__send__(:alias_method, stashed_method_name, @method)
        @method_is_stashed = true
      end

      private

      # @private
      def method_defined_directly_on_klass?
        method_defined_on_klass? && method_owned_by_klass?
      end

      # @private
      def method_defined_on_klass?(klass = @klass)
        klass.method_defined?(@method) || klass.private_method_defined?(@method)
      end

      def method_owned_by_klass?
        owner = @klass.instance_method(@method).owner
        # On some 1.9s (e.g. rubinius) aliased methods
        # can report the wrong owner. Example:
        # class MyClass
        #   class << self
        #     alias alternate_new new
        #   end
        # end
        #
        # MyClass.owner(:alternate_new) returns `Class` when incorrect,
        # but we need to consider the owner to be `MyClass` because
        # it is not actually available on `Class` but is on `MyClass`.
        # Hence, we verify that the owner actually has the method defined.
        # If the given owner does not have the method defined, we assume
        # that the method is actually owned by @klass.
        owner == @klass || !(method_defined_on_klass?(owner))
      end

      public

      # @private
      def stashed_method_name
        "obfuscated_by_rspec_mocks__#{@method}"
      end

      # @private
      def restore
        return unless @method_is_stashed

        if @klass.__send__(:method_defined?, @method)
          @klass.__send__(:undef_method, @method)
        end
        @klass.__send__(:alias_method, @method, stashed_method_name)
        @klass.__send__(:remove_method, stashed_method_name)
        @method_is_stashed = false
      end
    end
  end
end

