$LOAD_PATH.unshift "./lib"
require 'benchmark'
require 'rspec/expectations'
require 'securerandom'

extend RSpec::Matchers

sizes = [10, 100, 1000, 2000, 4000]

puts "rspec-expectations #{RSpec::Expectations::Version::STRING} -- #{RUBY_ENGINE}/#{RUBY_VERSION}"

puts
puts "Passing `match_array` expectation with lists of distinct strings"
puts

Benchmark.benchmark do |bm|
  sizes.each do |size|
    actual    = Array.new(size) { SecureRandom.uuid }
    expecteds = Array.new(3)    { actual.shuffle }
    expecteds.each do |expected|
      bm.report("#{size.to_s.rjust(5)} items") do
        expect(actual).to match_array(expected)
      end
    end
  end
end

__END__

Before new composable matchers algo:

   10 items  0.000000   0.000000   0.000000 (  0.000857)
   10 items  0.000000   0.000000   0.000000 (  0.000029)
   10 items  0.000000   0.000000   0.000000 (  0.000018)
  100 items  0.000000   0.000000   0.000000 (  0.000334)
  100 items  0.000000   0.000000   0.000000 (  0.000372)
  100 items  0.000000   0.000000   0.000000 (  0.000331)
 1000 items  0.030000   0.000000   0.030000 (  0.029778)
 1000 items  0.030000   0.000000   0.030000 (  0.030566)
 1000 items  0.030000   0.000000   0.030000 (  0.033150)
 2000 items  0.140000   0.000000   0.140000 (  0.141719)
 2000 items  0.120000   0.000000   0.120000 (  0.124348)
 2000 items  0.120000   0.000000   0.120000 (  0.121202)
 4000 items  0.490000   0.000000   0.490000 (  0.500631)
 4000 items  0.470000   0.000000   0.470000 (  0.468477)
 4000 items  0.490000   0.010000   0.500000 (  0.492957)

After:

   10 items  0.000000   0.000000   0.000000 (  0.001165)
   10 items  0.000000   0.000000   0.000000 (  0.000131)
   10 items  0.000000   0.000000   0.000000 (  0.000127)
  100 items  0.000000   0.000000   0.000000 (  0.005636)
  100 items  0.010000   0.000000   0.010000 (  0.004881)
  100 items  0.000000   0.000000   0.000000 (  0.004676)
 1000 items  0.500000   0.000000   0.500000 (  0.505676)
 1000 items  0.490000   0.000000   0.490000 (  0.483469)
 1000 items  0.490000   0.000000   0.490000 (  0.497841)
 2000 items  1.950000   0.000000   1.950000 (  1.966324)
 2000 items  1.970000   0.000000   1.970000 (  1.975567)
 2000 items  1.900000   0.000000   1.900000 (  1.902315)
 4000 items  7.650000   0.010000   7.660000 (  7.672907)
 4000 items  7.720000   0.010000   7.730000 (  7.735615)
 4000 items  7.730000   0.000000   7.730000 (  7.756837)

With "smaller subproblem" optimization: (about 20% slower)

   10 items  0.000000   0.000000   0.000000 (  0.001099)
   10 items  0.000000   0.000000   0.000000 (  0.000110)
   10 items  0.000000   0.000000   0.000000 (  0.000102)
  100 items  0.010000   0.000000   0.010000 (  0.005462)
  100 items  0.010000   0.000000   0.010000 (  0.005433)
  100 items  0.000000   0.000000   0.000000 (  0.005409)
 1000 items  0.570000   0.000000   0.570000 (  0.569302)
 1000 items  0.570000   0.000000   0.570000 (  0.577496)
 1000 items  0.560000   0.000000   0.560000 (  0.555496)
 2000 items  2.330000   0.000000   2.330000 (  2.325537)
 2000 items  2.450000   0.000000   2.450000 (  2.464415)
 2000 items  2.470000   0.000000   2.470000 (  2.472999)
 4000 items  9.380000   0.010000   9.390000 (  9.406678)
 4000 items  9.320000   0.010000   9.330000 (  9.340727)
 4000 items  9.330000   0.010000   9.340000 (  9.358326)

With "implement `values_match?` ourselves" optimization: (about twice as fast!)

   10 items  0.000000   0.000000   0.000000 (  0.001113)
   10 items  0.000000   0.000000   0.000000 (  0.000074)
   10 items  0.000000   0.000000   0.000000 (  0.000071)
  100 items  0.000000   0.000000   0.000000 (  0.002558)
  100 items  0.010000   0.000000   0.010000 (  0.002528)
  100 items  0.000000   0.000000   0.000000 (  0.002555)
 1000 items  0.300000   0.000000   0.300000 (  0.306318)
 1000 items  0.260000   0.000000   0.260000 (  0.253526)
 1000 items  0.240000   0.000000   0.240000 (  0.246096)
 2000 items  1.070000   0.000000   1.070000 (  1.065989)
 2000 items  1.040000   0.000000   1.040000 (  1.047495)
 2000 items  1.080000   0.000000   1.080000 (  1.078392)
 4000 items  4.520000   0.000000   4.520000 (  4.529568)
 4000 items  4.570000   0.010000   4.580000 (  4.597785)
 4000 items  5.030000   0.010000   5.040000 (  5.079452)

With `match_when_sorted?` optimization: (many orders of magnitude faster!)

   10 items  0.010000   0.000000   0.010000 (  0.002044)
   10 items  0.000000   0.000000   0.000000 (  0.000038)
   10 items  0.000000   0.000000   0.000000 (  0.000031)
  100 items  0.000000   0.000000   0.000000 (  0.000149)
  100 items  0.000000   0.000000   0.000000 (  0.000137)
  100 items  0.000000   0.000000   0.000000 (  0.000136)
 1000 items  0.000000   0.000000   0.000000 (  0.001426)
 1000 items  0.000000   0.000000   0.000000 (  0.001369)
 1000 items  0.000000   0.000000   0.000000 (  0.001355)
 2000 items  0.010000   0.000000   0.010000 (  0.003304)
 2000 items  0.000000   0.000000   0.000000 (  0.002192)
 2000 items  0.000000   0.000000   0.000000 (  0.002849)
 4000 items  0.000000   0.000000   0.000000 (  0.007730)
 4000 items  0.010000   0.000000   0.010000 (  0.006074)
 4000 items  0.010000   0.000000   0.010000 (  0.006514)

With e === a || a == e || values_match?(e,a)

   10 items  0.000000   0.000000   0.000000 (  0.002202)
   10 items  0.000000   0.000000   0.000000 (  0.000054)
   10 items  0.000000   0.000000   0.000000 (  0.000046)
  100 items  0.000000   0.000000   0.000000 (  0.000203)
  100 items  0.000000   0.000000   0.000000 (  0.000199)
  100 items  0.000000   0.000000   0.000000 (  0.000192)
 1000 items  0.010000   0.000000   0.010000 (  0.001438)
 1000 items  0.000000   0.000000   0.000000 (  0.001419)
 1000 items  0.000000   0.000000   0.000000 (  0.001474)
 2000 items  0.010000   0.000000   0.010000 (  0.003341)
 2000 items  0.000000   0.000000   0.000000 (  0.003224)
 2000 items  0.000000   0.000000   0.000000 (  0.003251)
 4000 items  0.010000   0.000000   0.010000 (  0.007156)
 4000 items  0.010000   0.000000   0.010000 (  0.006715)
 4000 items  0.000000   0.000000   0.000000 (  0.006676)

With values_match?(e,a)

   10 items  0.000000   0.000000   0.000000 (  0.001173)
   10 items  0.000000   0.000000   0.000000 (  0.000051)
   10 items  0.000000   0.000000   0.000000 (  0.000026)
  100 items  0.000000   0.000000   0.000000 (  0.000171)
  100 items  0.000000   0.000000   0.000000 (  0.000138)
  100 items  0.000000   0.000000   0.000000 (  0.000136)
 1000 items  0.010000   0.000000   0.010000 (  0.001506)
 1000 items  0.000000   0.000000   0.000000 (  0.001486)
 1000 items  0.000000   0.000000   0.000000 (  0.001510)
 2000 items  0.010000   0.000000   0.010000 (  0.003153)
 2000 items  0.000000   0.010000   0.010000 (  0.003883)
 2000 items  0.000000   0.000000   0.000000 (  0.003199)
 4000 items  0.010000   0.000000   0.010000 (  0.007178)
 4000 items  0.000000   0.000000   0.000000 (  0.006629)
 4000 items  0.010000   0.000000   0.010000 (  0.006435)
