RSpec::Matchers.define :include_method do |expected|
  match do |actual|
    actual.map { |m| m.to_s }.include?(expected.to_s)
  end
end

RSpec::Matchers.define :custom_include do |*args|
  match { |actual| expect(actual).to include(*args) }
end

RSpec::Matchers.define :be_a_clone_of do |expected|
  match do |actual|
    !actual.equal?(expected) &&
        actual.class.equal?(expected.class) &&
        state_of(actual) == state_of(expected)
  end

  def state_of(object)
    ivar_names = object.instance_variables
    Hash[ ivar_names.map { |n| [n, object.instance_variable_get(n)] } ]
  end
end

RSpec::Matchers.define :have_string_length do |expected|
  match do |actual|
    @actual = actual
    string_length == expected
  end

  def string_length
    @string_length ||= @actual.length
  end
end

module FailMatchers
  def fail
    raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  def fail_with(message)
    raise_error(RSpec::Expectations::ExpectationNotMetError, message)
  end

  def fail_including(snippet)
    raise_error(
      RSpec::Expectations::ExpectationNotMetError,
      a_string_including(snippet)
    )
  end
end

RSpec.configure do |config|
  config.include FailMatchers
end

RSpec::Matchers.define_negated_matcher :a_string_excluding, :a_string_including
