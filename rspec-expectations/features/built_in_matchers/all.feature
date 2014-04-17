Feature: all matcher

  Use the `all` matcher to specify that a collection's objects all pass an expected matcher.
  This works on any object that responds to #all? (array and any Enumerable object):

    ```ruby
    expect([1, 3, 5]).to all( be_odd )
    expect([1, 3, 5]).to all( be_an(Integer) )
    expect([1, 3, 5]).to all( be < 10 )
    expect([1, 3, 4]).to all( be_odd ) # fails
    ```

  The matcher also supports compound matchers:

    ```ruby
    expect([1, 3, 5]).to all( be_odd.and be < 10 )
    expect([1, 4, 21]).to all( be_odd.or be < 10 )
    ```

  Scenario: array usage
    Given a file named "array_all_matcher_spec.rb" with:
      """ruby
      RSpec.describe [1, 3, 5] do
        it { is_expected.to all( be_odd ) }
        it { is_expected.to all( be_an(Integer) ) }
        it { is_expected.to all( be < 10 ) }

        # deliberate failures
        it { is_expected.to all( be_even ) }
        it { is_expected.to all( be_a(String) ) }
        it { is_expected.to all( be < 0 ) }
        it { is_expected.to all( eq(8) ) }

        #  should fail since not all objects are greater then 2
        it { is_expected.to all( be > 2 ) }

        # should fail since not all objects are 3
        it { is_expected.to all( eq(3) ) }
      end
      """
    When I run `rspec array_all_matcher_spec.rb`
    Then the output should contain all of these:
      | 9 examples, 6 failures                        |
      | expected [1, 3, 5] to all be even             |
      | expected [1, 3, 5] to all be a kind of String |
      | expected [1, 3, 5] to all be < 0              |
      | expected [1, 3, 5] to all eq 8                |
      | expected [1, 3, 5] to all be > 2              |
      | expected [1, 3, 5] to all eq 3                |

  Scenario: compound matcher usage
    Given a file named "compound_all_matcher_spec.rb" with:
      """ruby
      RSpec.describe ['anything', 'everything', 'something'] do
        it { is_expected.to all( be_a(String).and include("thing") ) }
        it { is_expected.to all( be_a(String).and ending_with("g") ) }
        it { is_expected.to all( starting_with("s").or include("y") ) }

        # deliberate failures
        it { is_expected.to all( include("foo").and include("bar") ) }
        it { is_expected.to all( be_a(String).and starting_with("a") ) }
        it { is_expected.to all( starting_with("a").or include("z") ) }
      end
      """
    When I run `rspec compound_all_matcher_spec.rb`
    Then the output should contain all of these:
      | 6 examples, 3 failures                                                                              |
      | expected ["anything", "everything", "something"] to all include "foo" and include "bar"             |
      | expected ["anything", "everything", "something"] to all be a kind of String and starting with "a"   |
      | expected ["anything", "everything", "something"] to all starting with "a" or include "z"            |
