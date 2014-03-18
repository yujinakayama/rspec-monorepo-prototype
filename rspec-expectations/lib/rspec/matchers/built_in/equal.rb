module RSpec
  module Matchers
    module BuiltIn
      # @api private
      # Provides the implementation for `equal`.
      # Not intended to be instantiated directly.
      class Equal < BaseMatcher
        def failure_message
          if expected_is_a_literal_singleton?
            simple_failure_message
          else
            detailed_failure_message
          end
        end

        def failure_message_when_negated
          return <<-MESSAGE

expected not #{inspect_object(actual)}
         got #{inspect_object(expected)}

Compared using equal?, which compares object identity.

MESSAGE
        end

        def diffable?
          !expected_is_a_literal_singleton?
        end

      private

        def match(expected, actual)
          actual.equal? expected
        end

        LITERAL_SINGLETONS = [true, false, nil]

        def expected_is_a_literal_singleton?
          LITERAL_SINGLETONS.include?(expected)
        end

        def actual_inspected
          if LITERAL_SINGLETONS.include?(actual)
            actual.inspect
          else
            inspect_object(actual)
          end
        end

        def simple_failure_message
          "\nexpected #{expected.inspect}\n     got #{actual_inspected}\n"
        end

        def detailed_failure_message
          return <<-MESSAGE

expected #{inspect_object(expected)}
     got #{inspect_object(actual)}

Compared using equal?, which compares object identity,
but expected and actual are not the same object. Use
`expect(actual).to eq(expected)` if you don't care about
object identity in this example.

MESSAGE
        end

        def inspect_object(o)
          "#<#{o.class}:#{o.object_id}> => #{o.inspect}"
        end
      end
    end
  end
end
