require 'rspec/support/caller_filter'
require 'rspec/support/warnings'

require 'rspec/matchers'
require 'rspec/expectations/expectation_target'
require 'rspec/matchers/configuration'
require 'rspec/expectations/fail_with'
require 'rspec/expectations/handler'
require 'rspec/expectations/version'
require 'rspec/expectations/diff_presenter'

module RSpec
  # RSpec::Expectations provides a simple, readable API to express
  # the expected outcomes in a code example. To express an expected
  # outcome, wrap an object or block in `expect`, call `to` or `to_not`
  # (aliased as `not_to`) and pass it a matcher object:
  #
  #     expect(order.total).to eq(Money.new(5.55, :USD))
  #     expect(list).to include(user)
  #     expect(message).not_to match(/foo/)
  #     expect { do_something }.to raise_error
  #
  # The last form (the block form) is needed to match against ruby constructs
  # that are not objects, but can only be observed when executing a block
  # of code. This includes raising errors, throwing symbols, yielding,
  # and changing values.
  #
  # When `expect(...).to` is invoked with a matcher, it turns around
  # and calls `matcher.matches?(<object wrapped by expect>)`.  For example,
  # in the expression:
  #
  #     expect(order.total).to eq(Money.new(5.55, :USD))
  #
  # ...`eq(Money.new(5.55, :USD))` returns a matcher object, and it results
  # in the equivalent of `eq.matches?(order.total)`. If `matches?` returns
  # `true`, the expectation is met and execution continues. If `false`, then
  # the spec fails with the message returned by `eq.failure_message`.
  #
  # Given the expression:
  #
  #     expect(order.entries).not_to include(entry)
  #
  # ...the `not_to` method (also available as `to_not`) invokes the equivalent of
  # `include.matches?(order.entries)`, but it interprets `false` as success, and
  # `true` as a failure, using the message generated by
  # `eq.failure_message_when_negated`.
  #
  # rspec-expectations ships with a standard set of useful matchers, and writing
  # your own matchers is quite simple.
  #
  # See [RSpec::Matchers](../RSpec/Matchers) for more information about the
  # built-in matchers that ship with rspec-expectations, and how to write your
  # own custom matchers.
  module Expectations
    # Exception raised when an expectation fails.
    #
    # @note We subclass Exception so that in a stub implementation if
    # the user sets an expectation, it can't be caught in their
    # code by a bare `rescue`.
    # @api public
    ExpectationNotMetError = Class.new(::Exception)
  end
end

