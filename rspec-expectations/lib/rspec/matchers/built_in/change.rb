module RSpec
  module Matchers
    module BuiltIn
      # Describes an expected mutation.
      class Change
        # Specifies the delta of the expected change.
        def by(expected_delta)
          @expected_delta = expected_delta
          self
        end

        # Specifies a minimum delta of the expected change.
        def by_at_least(minimum)
          @minimum = minimum
          self
        end

        # Specifies a maximum delta of the expected change.
        def by_at_most(maximum)
          @maximum = maximum
          self
        end

        # Specifies the new value you expect.
        def to(to)
          @eval_after = true
          @expected_after = to
          self
        end

        # Specifies the original value.
        def from(before)
          @eval_before = true
          @expected_before = before
          self
        end

        # @api private
        def matches?(event_proc)
          raise_block_syntax_error if block_given?

          @actual_before = evaluate_value_proc
          event_proc.call
          @actual_after = evaluate_value_proc

          (!change_expected? || changed?) && matches_before? && matches_after? && matches_expected_delta? && matches_min? && matches_max?
        end
        alias == matches?

        # @api private
        def failure_message
          if @eval_before && !expected_matches_actual?(@expected_before, @actual_before)
            "expected #{message} to have initially been #{@expected_before.inspect}, but was #{@actual_before.inspect}"
          elsif @eval_after && !expected_matches_actual?(@expected_after, @actual_after)
            "expected #{message} to have changed to #{failure_message_for_expected_after}, but is now #{@actual_after.inspect}"
          elsif @expected_delta
            "expected #{message} to have changed by #{@expected_delta.inspect}, but was changed by #{actual_delta.inspect}"
          elsif @minimum
            "expected #{message} to have changed by at least #{@minimum.inspect}, but was changed by #{actual_delta.inspect}"
          elsif @maximum
            "expected #{message} to have changed by at most #{@maximum.inspect}, but was changed by #{actual_delta.inspect}"
          else
            "expected #{message} to have changed, but is still #{@actual_before.inspect}"
          end
        end

        # @api private
        def failure_message_when_negated
          "expected #{message} not to have changed, but did change from #{@actual_before.inspect} to #{@actual_after.inspect}"
        end

        # @api private
        def description
          "change ##{message}"
        end

      private

        def initialize(receiver=nil, message=nil, &block)
          @message = message
          @value_proc = block || lambda { receiver.__send__(message) }
          @expected_after = @expected_before = @minimum = @maximum = @expected_delta = nil
          @eval_before = @eval_after = false
        end

        def actual_delta
          @actual_after - @actual_before
        end

        def raise_block_syntax_error
          raise SyntaxError,
            "The block passed to the `change` matcher must use `{ ... }` instead of do/end"
        end

        def evaluate_value_proc
          case val = @value_proc.call
          when Enumerable, String
            val.dup
          else
            val
          end
        end

        def failure_message_for_expected_after
          if RSpec::Matchers.is_a_matcher?(@expected_after)
            @expected_after.description
          else
            @expected_after.inspect
          end
        end

        def message
          @message || "result"
        end

        def change_expected?
          @expected_delta != 0
        end

        def changed?
          @actual_before != @actual_after
        end

        def matches_before?
          @eval_before ? expected_matches_actual?(@expected_before, @actual_before) : true
        end

        def matches_after?
          @eval_after ? expected_matches_actual?(@expected_after, @actual_after) : true
        end

        def matches_expected_delta?
          @expected_delta ? (@actual_before + @expected_delta == @actual_after) : true
        end

        def matches_min?
          @minimum ? (@actual_after - @actual_before >= @minimum) : true
        end

        def matches_max?
          @maximum ? (@actual_after - @actual_before <= @maximum) : true
        end

        def expected_matches_actual?(expected, actual)
          expected === actual || actual == expected
        end
      end
    end
  end
end
