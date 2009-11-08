module Rspec # :nodoc:
  module Mocks # :nodoc:
    module Version # :nodoc:
      unless defined?(MAJOR)
        MAJOR  = 2
        MINOR  = 0
        TINY   = 0
        PRE    = 'a2'

        STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

        SUMMARY = "rspec-mocks " + STRING
      end
    end
  end
end
