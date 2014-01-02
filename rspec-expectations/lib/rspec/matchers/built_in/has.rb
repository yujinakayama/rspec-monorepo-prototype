module RSpec
  module Matchers
    module BuiltIn
      class Has
        include Composable

        def initialize(method_name, *args)
          @method_name, @args = method_name, args
        end

        def matches?(actual)
          actual.__send__(predicate, *@args)
        end

        def failure_message
          "expected ##{predicate}#{failure_message_args_description} to return true, got false"
        end

        def failure_message_when_negated
          "expected ##{predicate}#{failure_message_args_description} to return false, got true"
        end

        def description
          [method_description, args_description].compact.join(' ')
        end

      private

        REGEX = /^(?:have_)(.*)/

        def predicate
          @predicate ||= :"has_#{@method_name.to_s.match(REGEX).captures.first}?"
        end

        def method_description
          @method_name.to_s.gsub('_', ' ')
        end

        def args_description
          return nil if @args.empty?
          @args.map { |arg| arg.inspect }.join(', ')
        end

        def failure_message_args_description
          desc = args_description
          "(#{desc})" if desc
        end
      end
    end
  end
end
