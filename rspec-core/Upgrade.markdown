# Upgrade to rspec-core-2.0

## What's changed

### RSpec namespace

The root namespace is now `RSpec` instead of `Spec`, and the root directory
under `lib` is `rspec` instead of `spec`.

### Configuration

Typically in `spec/spec_helper.rb`, configuration is now done like this:

    RSpec.configure do |c|
      # ....
    end

### rspec commmand

The command to run specs is now `rspec` instead of `spec`.

    rspec ./spec

## What's new

### Runner

The new runner for rspec-2 comes from Micronaut.

### Metadata!

In rspec-2, every example and example group comes with metadata information
like the file and line number on which it was declared, the arguments passed to
`describe` and `it`, etc.  This metadata can be appended to through a hash
argument passed to `describe` or `it`, allowing us to pre and post-process
each example in a variety of ways.

The most obvious use is for filtering the run. For example:

    # in spec/spec_helper.rb
    RSpec.configure do |c|
      c.filter_run :focus => true
    end

    # in any spec file
    describe "something" do
      it "does something", :focus => true do
        # ....
      end
    end

When you run the `rspec` command, rspec will run only the examples that have
`:focus => true` in the hash. 

You can also add `run_all_when_everything_filtered` to the config:

    RSpec.configure do |c|
      c.filter_run :focus => true
      c.run_all_when_everything_filtered = true
    end

Now if there are no examples tagged with `:focus => true`, all examples
will be run. This makes it really easy to focus on one example for a
while, but then go back to running all of the examples by removing that
argument from `it`. Works with `describe` too, in which case it runs
all of the examples in that group.

The configuration will accept a lambda, which provides a lot of flexibility
in filtering examples. Say, for example, you have a spec for functionality that
behaves slightly differently in Ruby 1.8 and Ruby 1.9. We have that in
rspec-core, and here's how we're getting the right stuff to run under the
right version:

    # in spec/spec_helper.rb
    RSpec.configure do |c|
      c.exclusion_filter = { :ruby => lambda {|version|
        !(RUBY_VERSION.to_s =~ /^#{version.to_s}/)
      }}
    end

    # in any spec file
    describe "something" do
      it "does something", :ruby => 1.8 do
        # ....
      end

      it "does something", :ruby => 1.9 do
        # ....
      end
    end

In this case, we're using `exclusion_filter` instead of `filter_run` or
`filter`, which indicate _inclusion_ filters. So each of those examples is
excluded if we're _not_ running the version of Ruby they work with.
