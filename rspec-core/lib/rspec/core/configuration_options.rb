require 'optparse'
# http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html

module RSpec
  module Core

    class ConfigurationOptions
      LOCAL_OPTIONS_FILE  = ".rspec"
      GLOBAL_OPTIONS_FILE = File.join(File.expand_path("~"), ".rspec")
      
      attr_reader :args, :options
      
      def initialize(args)
        @args = args
        @options = {}
      end
      
      def apply_to(config)
        merged_options.each do |key, value|
          config.send("#{key}=", value)
        end
      end

      def parse_command_line_options
        @options = Parser.parse!(@args)
        @options[:files_or_directories_to_run] = @args
        @options
      end

    private

      def merged_options
        [global_options, local_options, command_line_options].inject do |merged, options|
          merged.merge(options)
        end
      end

      def command_line_options
        parse_command_line_options
      end

      class Parser
        def self.parse!(args)
          new.parse!(args)
        end

        class << self
          alias_method :parse, :parse!
        end

        def parse!(args)
          options = {}
          parser(options).parse!(args)
          options
        end

        alias_method :parse, :parse!

        def parser(options)
          OptionParser.new do |parser|
            parser.banner = "Usage: rspec [options] [files or directories]"

            parser.on('-b', '--backtrace', 'Enable full backtrace') do |o|
              options[:full_backtrace] = true
            end

            parser.on('-c', '--[no-]color', '--[no-]colour', 'Enable color in the output') do |o|
              options[:color_enabled] = o
            end
            
            parser.on('-d', '--debug', 'Enable debugging') do |o|
              options[:debug] = true
            end

            parser.on('-e', '--example PATTERN', "Run examples whose full descriptions match this pattern",
                    "(PATTERN is compiled into a Ruby regular expression)") do |o|
              options[:full_description] = /#{o}/
            end

            parser.on('-f', '--formatter FORMATTER', 'Choose a formatter',
                    '  [p]rogress (default - dots)',
                    '  [d]ocumentation (group and example names)') do |o|
              options[:formatter] = o
            end

            parser.on_tail('-h', '--help', "You're looking at it.") do 
              puts parser
              exit
            end

            parser.on('-I DIRECTORY', 'specify $LOAD_PATH directory (may be used more than once)') do |dir|
              options[:libs] ||= []
              options[:libs] << dir
            end

            parser.on('-l', '--line_number LINE', 'Specify the line number of a single example to run') do |o|
              options[:line_number] = o
            end

            parser.on('-o', '--options PATH', 'Read configuration options from a file path.  (Defaults to spec/spec.parser)') do |o|
              options[:options_file] = o || local_options_file
            end
            
            parser.on('-p', '--profile', 'Enable profiling of examples with output of the top 10 slowest examples') do |o|
              options[:profile_examples] = o
            end
          end
        end
      end

      def global_options
        parse_options_file(GLOBAL_OPTIONS_FILE)
      end

      def local_options
        parse_options_file(local_options_file)
      end
      
      def parse_options_file(path)
        Parser.parse(args_from_options_file(path))
      end

      def args_from_options_file(path)
        return [] unless File.exist?(path)
        File.readlines(path).map {|l| l.split}.flatten
      end

      def local_options_file
        return @options.delete(:options_file) if @options[:options_file]
        return LOCAL_OPTIONS_FILE if File.exist?(LOCAL_OPTIONS_FILE)
        RSpec.deprecate("spec/spec.opts", ".rspec or ~/.rspec", "2.0.0") if File.exist?("spec/spec.opts")
        "spec/spec.opts"
      end

    end
  end
end
