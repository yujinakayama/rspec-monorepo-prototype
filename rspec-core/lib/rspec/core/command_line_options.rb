require 'optparse'
# http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html

module Rspec
  module Core

    class CommandLineOptions
      
      attr_reader :args, :options, :config
      
      def self.parse(args, config)
        cli_options = new(args)
        cli_options.parse
      end

      def initialize(args)
        @args = args
        @options = {}
      end

      def parse
        possible_files = OptionParser.new do |opts|
          opts.banner = "Usage: rspec [options] [files or directories]"

          opts.on('-c', '--[no-]color', '--[no-]colour', 'Enable color in the output') do |o|
            @options[:color_enabled] = o
          end
          
          opts.on('-f', '--formatter [FORMATTER]', 'Choose an optional formatter') do |o|
            options[:formatter] = o
          end

          opts.on('-p', '--profile', 'Enable profiling of examples with output of the top 10 slowest examples') do |o|
            options[:profile_examples] = o
          end

          opts.on_tail('-h', '--help', "You're looking at it.") do 
            puts opts
          end
        end.parse!(@args)
        options[:files_to_run] = possible_files
        options
      end

    end

  end
end
